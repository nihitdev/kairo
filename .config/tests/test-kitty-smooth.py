#!/usr/bin/env python3
"""Isolated installer/fallback tests; never build or install to the live HOME."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class SmoothTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base / "home with ' quote"
        self.home.mkdir()
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        shutil.copytree(ROOT / '.config', self.repo / '.config')
        shutil.copytree(ROOT / '.local', self.repo / '.local')
        script = (ROOT / 'install.sh').read_text()
        script = script.replace('9932e8542edf5421ef326b9ba9434e925141cb38ab92e98386cb05f1ffd9411d', hashlib.sha256(b'fixture patch').hexdigest())
        (self.repo / 'install.sh').write_text(script)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / 'config'),
                        XDG_DATA_HOME=str(self.home / 'data'), XDG_STATE_HOME=str(self.home / 'state'),
                        XDG_CACHE_HOME=str(self.home / 'cache'), PATH=f'{self.bin}:{os.environ["PATH"]}',
                        CI='true', SMOOTH_FIXTURE=str(self.base))
        self.write_exe('git', '''#!/bin/bash
set -eu
if [[ $1 == clone ]]; then
    mkdir -p "${@: -1}"
    cp "$SMOOTH_FIXTURE/setup.py" "${@: -1}/setup.py"
elif [[ $3 == rev-parse ]]; then
    echo "${TEST_PIN:-b2cb871254fbdac19a085188813c8dfb258b95cd}"
elif [[ $3 == apply ]]; then
    [[ ${TEST_PATCH_FAIL:-0} == 0 ]]
else exit 1; fi
''')
        self.write_exe('curl', '#!/bin/bash\nprintf "%s" "${TEST_PATCH:-fixture patch}" > "${@: -1}"\n')
        for name in ('slangc', 'go', 'cc', 'pkg-config', 'fc-list', 'tic'):
            self.write_exe(name, '#!/bin/sh\nexit 0\n')
        self.write_exe('kitty', '#!/bin/sh\nprintf "stock:%s\\n" "$*"\n')
        (self.base / 'setup.py').write_text('''from pathlib import Path
import os, sys
if os.getenv('TEST_BUILD_FAIL'): sys.exit(1)
p = Path(sys.argv[sys.argv.index('--prefix')+1]) / 'bin/kitty'
p.parent.mkdir(parents=True)
p.write_text('#!/bin/sh\\nprintf "smooth:%s\\\\n" "$*"\\n')
p.chmod(0o755)
''')

    def write_exe(self, name, text):
        p = self.bin / name
        p.write_text(text)
        p.chmod(0o755)

    def run_install(self, *args, success=True):
        result = subprocess.run(['bash', str(self.repo / 'install.sh'), '--no-backup', '--only', 'kitty-smooth', *args],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_dry_run(self):
        result = self.run_install('--dry-run')
        self.assertIn('stock Kitty fallback', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_install_preserve_fallback_and_repeat(self):
        conf = self.home / 'config/kitty/user.conf'
        conf.parent.mkdir(parents=True)
        conf.write_text('font_size 19\nbackground_opacity 0.73\ncursor_trail 2\n')
        self.run_install()
        self.assertIn('font_size 19\nbackground_opacity 0.73\n', conf.read_text())
        self.assertIn('cursor_trail 0\n', conf.read_text())
        self.assertIn('cursor_smooth_motion_max_stretch 3 2', conf.read_text())
        launcher = self.home / '.local/bin/kitty-smooth'
        result = subprocess.check_output([str(launcher), 'nvim', 'a b'], env=self.env, text=True)
        self.assertIn('smooth:', result)
        self.assertIn('nvim a b', result)
        desktop = self.home / 'data/applications/kitty-smooth.desktop'
        self.assertIn('Exec="', desktop.read_text())
        if shutil.which('desktop-file-validate'):
            subprocess.run(['desktop-file-validate', str(desktop)], check=True)
        self.run_install()
        self.assertFalse((self.home / '.dotfiles-backup').exists())
        shutil.rmtree(self.home / '.local/kitty-smooth')
        result = subprocess.check_output([str(launcher), 'nvim'], env=self.env, text=True)
        self.assertEqual(result.strip(), 'stock:nvim')

    def test_cached_build_skips_network_and_repairs_launcher(self):
        self.run_install()
        binary = self.home / '.local/kitty-smooth/bin/kitty'
        before = binary.stat().st_mtime_ns
        (self.home / '.local/bin/kitty-smooth').unlink()
        for name in ('git', 'curl', 'cc', 'pkg-config'):
            self.write_exe(name, '#!/bin/sh\nexit 97\n')
        result = self.run_install()
        self.assertIn('pinned build already current', result.stdout)
        self.assertEqual(binary.stat().st_mtime_ns, before)
        self.assertTrue((self.home / '.local/bin/kitty-smooth').is_file())
        self.assertNotIn('Build Kitty Smooth:', self.run_install('--dry-run').stdout)
        self.run_install('--rebuild-kitty-smooth', success=False)
        self.assertEqual(binary.stat().st_mtime_ns, before)

    def test_stale_pin_rebuilds(self):
        self.run_install()
        marker = self.home / '.local/kitty-smooth/.kairo-build'
        marker.write_text('kitty=old\npatch=old\n')
        self.assertIn('Building Kitty Smooth', self.run_install().stdout)
        self.assertNotIn('old', marker.read_text())

    def test_failures_preserve_existing(self):
        target = self.home / '.local/kitty-smooth/bin/kitty'
        target.parent.mkdir(parents=True)
        target.write_text('old binary')
        for key, value in [('TEST_PIN', 'wrong'), ('TEST_PATCH', 'tampered'), ('TEST_PATCH_FAIL', '1'), ('TEST_BUILD_FAIL', '1')]:
            with self.subTest(key=key):
                self.env[key] = value
                self.run_install(success=False)
                self.assertEqual(target.read_text(), 'old binary')
                self.env.pop(key)

    def test_late_failure_rolls_back(self):
        target = self.home / '.local/kitty-smooth/bin/kitty'
        target.parent.mkdir(parents=True)
        target.write_text('old binary')
        real_cp = shutil.which('cp')
        self.write_exe('cp', f'''#!/bin/bash
for arg in "$@"; do
    if [[ $arg == */kitty-smooth.desktop ]]; then exit 1; fi
done
exec {real_cp} "$@"
''')
        self.run_install(success=False)
        self.assertEqual(target.read_text(), 'old binary')
        self.assertFalse((self.home / '.local/bin/kitty-smooth').exists())

    @unittest.skipUnless(shutil.which('lua'), 'Lua not installed')
    def test_hyprland_fallback(self):
        program = ROOT / '.config/hypr/config/programs.lua'
        code = f'dofile("{program}"); os.execute(P.terminal); os.execute(P.editor)'
        result = subprocess.check_output(['lua', '-e', code], env=self.env, text=True)
        self.assertEqual(result, 'stock:\nstock:nvim\n')
        launcher = self.home / '.local/bin/kitty-smooth'
        launcher.parent.mkdir(parents=True)
        shutil.copy(ROOT / '.local/bin/kitty-smooth', launcher)
        code = f'dofile("{program}"); os.execute(P.editor)'
        result = subprocess.check_output(['lua', '-e', code], env=self.env, text=True)
        self.assertEqual(result.strip(), 'stock:nvim')


if __name__ == '__main__':
    unittest.main()
