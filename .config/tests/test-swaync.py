#!/usr/bin/env python3
"""SwayNC deployment and battery alerts, isolated from the live desktop."""

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


class SwayNCTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / 'home with spaces'
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), CI='true')
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

    def assert_payload(self):
        for name in ('config.json', 'style.css'):
            self.assertEqual((self.home / 'config/swaync' / name).read_bytes(),
                             (ROOT / '.config/swaync' / name).read_bytes())
        installed = self.home / '.local/bin/battery-guardian'
        self.assertEqual(installed.read_bytes(), GUARDIAN.read_bytes())
        self.assertTrue(os.access(installed, os.X_OK))
        self.assertFalse((self.home / '.dotfiles-backup').exists())

    def test_normal_install_includes_swaync(self):
        self.install()
        self.assert_payload()

    def test_scoped_install_preserves_unrelated_files_and_repeats(self):
        config = self.home / 'config/swaync'
        config.mkdir(parents=True)
        (config / 'personal.css').write_text('/* keep */')
        before = sorted(self.home.rglob('*'))
        plan = self.install('--only', 'swaync', '--dry-run').stdout
        self.assertIn('battery-guardian', plan)
        self.assertEqual(before, sorted(self.home.rglob('*')))
        self.install('--only', 'swaync')
        self.assert_payload()
        self.assertEqual((config / 'personal.css').read_text(), '/* keep */')
        self.assertFalse((self.home / 'config/hypr').exists())
        repeat = self.install('--only', 'swaync').stdout
        self.assertIn('Already current: swaync', repeat)
        self.assertNotIn('Replace ', repeat)

    def test_launcher_escape_rejected_before_deployment(self):
        outside = Path(self.temporary.name) / 'outside'
        outside.mkdir()
        (self.home / '.local').mkdir()
        (self.home / '.local/bin').symlink_to(outside, target_is_directory=True)
        self.assertNotEqual(self.install('--only', 'swaync', check=False).returncode, 0)
        self.assertFalse((self.home / 'config/swaync').exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_timeouts_and_grouping(self):
        config = json.loads((ROOT / '.config/swaync/config.json').read_text())
        for key in ('timeout', 'timeout-low', 'timeout-critical'):
            self.assertEqual(config[key], 10)
        self.assertTrue(config['notification-grouping'])

    def test_failed_guardian_copy_rolls_back_swaync(self):
        config = self.home / 'config/swaync'
        config.mkdir(parents=True)
        for name in ('config.json', 'style.css', 'personal.css'):
            (config / name).write_text('original ' + name)
        mock_bin = self.home / 'mock-bin'
        mock_bin.mkdir()
        copier = mock_bin / 'cp'
        copier.write_text('#!/usr/bin/env bash\n'
                          '[[ $* != *battery-guardian* ]] || exit 1\n'
                          'exec "$REAL_CP" "$@"\n')
        copier.chmod(0o755)
        self.env['REAL_CP'] = shutil.which('cp')
        self.env['PATH'] = str(mock_bin) + os.pathsep + self.env['PATH']
        self.assertNotEqual(self.install('--only', 'swaync', check=False).returncode, 0)
        for name in ('config.json', 'style.css', 'personal.css'):
            self.assertEqual((config / name).read_text(), 'original ' + name)
        self.assertFalse((self.home / '.local/bin/battery-guardian').exists())
        self.assertFalse((self.home / '.dotfiles-backup').exists())

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
local guardians, swaync, waybar = 0, 0, 0
for _, command in ipairs(commands) do
    if command:find('battery-guardian', 1, true) then guardians = guardians + 1 end
    if command:find('-x swaync', 1, true) then swaync = swaync + 1 end
    if command:find('-x waybar', 1, true) then waybar = waybar + 1 end
end
assert(guardians == 1 and swaync == 1 and waybar == 1)
assert(namespaces['^swaync-control-center$'] == 1)
assert(namespaces['^swaync-notification-window$'] == 1)
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
