#!/usr/bin/env python3
"""Exercise cross-theme rollback through the real parent installer, in a staging root."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ThemeTransactionTest(unittest.TestCase):
    def test_plymouth_failure_restores_sddm_and_home(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            repo, home, system, commands = [base / name for name in ('repo', 'home', 'system', 'bin')]
            repo.mkdir()
            home.mkdir()
            commands.mkdir()
            shutil.copy2(ROOT / 'install.sh', repo / 'install.sh')
            for name in ('.config', '.local'):
                shutil.copytree(ROOT / name, repo / name)
            (home / '.bashrc').write_text('previous bash config\n')
            conf = system / 'etc/sddm.conf.d/zz-archnemesis.conf'
            conf.parent.mkdir(parents=True)
            conf.write_text('[Theme]\nCurrent=previous\n')
            theme = repo / '.local/share/sddm/themes/archnemesis'
            (theme / 'install.sh').rename(theme / 'real-install.sh')
            # The real helper finds rollback.sh in its own directory.
            (theme / 'rollback.sh').rename(theme / 'real-rollback.sh')
            (theme / 'install.sh').write_text(
                '#!/bin/bash\nexec bash "$(dirname "$0")/real-install.sh" --destdir "$TEST_SYSTEM" "$@"\n')
            (theme / 'rollback.sh').write_text(
                '#!/bin/bash\nexec bash "$(dirname "$0")/real-rollback.sh" "$1" --destdir "$TEST_SYSTEM"\n')
            (repo / '.local/share/plymouth/install.sh').write_text(
                '#!/bin/bash\n[[ ${1:-} == --dry-run ]] && exit 0\nexit 83\n')
            (commands / 'sudo').write_text('#!/bin/sh\n[ "$1" = -v ]\n')
            (commands / 'sudo').chmod(0o755)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
                       XDG_DATA_HOME=str(home / '.local/share'), XDG_STATE_HOME=str(home / '.local/state'),
                       XDG_CACHE_HOME=str(home / '.cache'), TEST_SYSTEM=str(system),
                       PATH=f'{commands}:{os.environ["PATH"]}', CI='true')
            result = subprocess.run(['bash', str(repo / 'install.sh'), '--only', 'bash', '--only', 'sddm',
                                     '--only', 'plymouth'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 83, result.stdout + result.stderr)
            self.assertIn('Restoring SDDM', result.stderr)
            self.assertEqual(conf.read_text(), '[Theme]\nCurrent=previous\n')
            self.assertFalse((system / 'usr/share/sddm/themes/archnemesis').exists())
            self.assertEqual((home / '.bashrc').read_text(), 'previous bash config\n')


if __name__ == '__main__':
    unittest.main()
