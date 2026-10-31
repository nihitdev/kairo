#!/usr/bin/env python3
"""Quickshell notification startup and battery alerts, isolated from the live desktop."""

import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GUARDIAN = ROOT / '.local/bin/battery-guardian'


class NotificationsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / 'home with spaces'
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), CI='true')
        self.env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + self.temporary.name + '/no-session-bus'
        for name, directory in (('CONFIG', 'config'), ('DATA', 'data'),
                                ('STATE', 'state'), ('CACHE', 'cache'),
                                ('RUNTIME', 'runtime')):
            self.env[f'XDG_{name}_HOME' if name != 'RUNTIME' else 'XDG_RUNTIME_DIR'] = str(self.home / directory)
        for name in ('KAIRO_BIN_DIR', 'QS_STATE_DIR', 'BATTERY_GUARDIAN_BATTERY',
                     'BATTERY_GUARDIAN_INTERVAL'):
            self.env.pop(name, None)

    def install(self, *args, check=True):
        return subprocess.run(['bash', str(ROOT / 'install.sh'), '--no-backup', *args],
                              env=self.env, text=True, capture_output=True,
                              check=check, timeout=60)

    def test_default_plan_uses_quickshell_notifications(self):
        # Defaults include system-wide SDDM; preview selection without sudo writes.
        plan = self.install('--dry-run').stdout
        self.assertIn('quickshell/hyprland-notifications', plan)
        self.assertIn('battery-guardian', plan)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_guardian_destination_escape_rejected_before_deployment(self):
        outside = Path(self.temporary.name) / 'outside'
        outside.mkdir()
        (self.home / '.local').mkdir()
        (self.home / '.local/bin').symlink_to(outside, target_is_directory=True)
        result = self.install('--only', 'hypr', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / 'config/hypr').exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_failed_guardian_copy_rolls_back_notification_payload(self):
        config = self.home / 'config/quickshell/hyprland-notifications'
        config.mkdir(parents=True)
        (config / 'shell.qml').write_text('original notification shell')
        mock_bin = self.home / 'mock-bin'
        mock_bin.mkdir()
        copier = mock_bin / 'cp'
        copier.write_text('#!/usr/bin/env bash\n'
                          '[[ $* != *battery-guardian* ]] || exit 1\n'
                          'exec "$REAL_CP" "$@"\n')
        copier.chmod(0o755)
        self.env['REAL_CP'] = shutil.which('cp')
        self.env['PATH'] = str(mock_bin) + os.pathsep + self.env['PATH']
        result = self.install('--only', 'hypr', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((config / 'shell.qml').read_text(), 'original notification shell')
        self.assertEqual(list(config.iterdir()), [config / 'shell.qml'])
        self.assertFalse((self.home / '.local/bin/battery-guardian').exists())
        self.assertFalse((self.home / 'config/hypr').exists())

    @unittest.skipUnless(shutil.which('lua'), 'Lua is unavailable')
    def test_autostart_and_existing_blur_rules(self):
        self.install('--only', 'hypr')
        script = '''
local commands, namespaces = {}, {}
hl = {
    on = function(_, callback) callback() end,
    exec_cmd = function(command) table.insert(commands, command) end,
    layer_rule = function(rule)
        local name = rule.match.namespace
        namespaces[name] = (namespaces[name] or 0) + 1
        assert(rule.blur)
    end,
}
dofile(arg[1])
dofile(arg[2])
local guardians, centers = 0, 0
for _, command in ipairs(commands) do
    if command:find('battery-guardian', 1, true) then guardians = guardians + 1 end
    if command:find('hyprland-notifications', 1, true) then centers = centers + 1 end
end
assert(guardians == 1 and centers == 1)
assert(namespaces['^waybar$'] == 1)
assert(namespaces['^rofi$'] == 1)
'''
        subprocess.run(['lua', '-', str(self.home / 'config/hypr/config/autostart.lua'),
                        str(ROOT / '.config/hypr/config/layers.lua')],
                       input=script, text=True, check=True, capture_output=True, timeout=5)

    def battery_fixture(self, samples):
        battery = self.home / 'BAT0'
        battery.mkdir()
        (battery / 'capacity').write_text('50\n')
        (battery / 'status').write_text('Discharging\n')
        self.env['BATTERY_GUARDIAN_BATTERY'] = str(battery)
        self.env['BATTERY_SAMPLES'] = json.dumps(samples)
        mock_bin = self.home / 'mock-bin'
        mock_bin.mkdir()
        self.env['PATH'] = str(mock_bin) + os.pathsep + self.env['PATH']
        scripts = {
            'sleep': '''import json, os
from pathlib import Path
root = Path(os.environ['HOME'])
counter = root / 'step'
step = int(counter.read_text()) if counter.exists() else 0
samples = json.loads(os.environ['BATTERY_SAMPLES'])
if step >= len(samples):
    raise SystemExit(1)
capacity, status = samples[step]
battery = Path(os.environ['BATTERY_GUARDIAN_BATTERY'])
(battery / 'capacity').write_text(str(capacity) + '\\n')
(battery / 'status').write_text(status + '\\n')
counter.write_text(str(step + 1))
''',
            'notify-send': '''import json, os, sys
from pathlib import Path
with (Path(os.environ['HOME']) / 'notifications').open('a') as output:
    output.write(json.dumps(sys.argv[1:]) + '\\n')
''',
        }
        for name, script in scripts.items():
            path = mock_bin / name
            path.write_text('#!/usr/bin/env python3\n' + script)
            path.chmod(0o755)

    def run_guardian(self):
        subprocess.run([str(GUARDIAN)], env=self.env, check=True,
                       capture_output=True, text=True, timeout=10)

    def test_battery_thresholds_reset_and_timeout(self):
        self.battery_fixture([(20, 'Discharging'), (19, 'Discharging'),
                              (10, 'Discharging'), (5, 'Discharging'),
                              (4, 'Discharging'), (30, 'Charging'),
                              (20, 'Discharging'), ('invalid', 'Discharging')])
        self.run_guardian()
        notifications = [json.loads(line) for line in
                         (self.home / 'notifications').read_text().splitlines()]
        self.assertEqual(len(notifications), 4)
        self.assertEqual([args[1] for args in notifications],
                         ['normal', 'critical', 'critical', 'normal'])
        self.assertTrue(all(args[2:4] == ['-t', '10000'] for args in notifications))

    def test_existing_watcher_lock_prevents_duplicate(self):
        self.battery_fixture([(5, 'Discharging')])
        runtime = Path(self.env['XDG_RUNTIME_DIR'])
        runtime.mkdir()
        with (runtime / 'battery-guardian.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.run_guardian()
        self.assertFalse((self.home / 'notifications').exists())
        self.assertFalse((self.home / 'step').exists())


if __name__ == '__main__':
    unittest.main()
