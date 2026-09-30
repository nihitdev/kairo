#!/usr/bin/env python3
"""Install modular shells in fixtures without network or account changes."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ShellConfigsTest(unittest.TestCase):
    def test_shells_plugins_and_repeat_install(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / 'home with spaces'
            home.mkdir()
            mock_bin = root / 'bin'
            mock_bin.mkdir()
            packages = ('zsh fish zsh-autosuggestions zsh-syntax-highlighting '
                        'zsh-completions zsh-history-substring-search git fzf fd '
                        'eza bat neovim yazi lazygit btop starship zoxide mise direnv')
            (mock_bin / 'pacman').write_text(
                '#!/usr/bin/env bash\n'
                '[[ $1 == -Qq ]] || exit 1\n'
                "printf '%s\\n' " + packages + '\n')
            (mock_bin / 'git').write_text('''#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$SHELL_TEST_GIT_CALLS"
if [[ $1 == clone ]]; then
    target=${@: -1}
    mkdir -p "$target"
    case ${target##*/} in
        oh-my-zsh) entry=oh-my-zsh.sh ;;
        fzf-tab) entry=fzf-tab.plugin.zsh ;;
        zsh-autopair) entry=autopair.zsh ;;
        zsh-you-should-use) entry=you-should-use.plugin.zsh ;;
        forgit) entry=forgit.plugin.zsh ;;
        *) exit 1 ;;
    esac
    printf '# plugin fixture\n' > "$target/$entry"
elif [[ $1 == -C && $3 == reset && $4 == --hard ]]; then
    [[ $5 =~ ^[0-9a-f]{40}$ ]]
else
    exit 1
fi
''')
            for file in mock_bin.iterdir():
                file.chmod(0o755)
            env = dict(os.environ, HOME=str(home), CI='true',
                       PATH=str(mock_bin) + os.pathsep + os.environ['PATH'],
                       SHELL_TEST_GIT_CALLS=str(root / 'git-calls'))
            for name, suffix in (('CONFIG', '.config'), ('DATA', '.local/share'),
                                 ('CACHE', '.cache'), ('STATE', '.local/state')):
                env[f'XDG_{name}_HOME'] = str(home / suffix)
            for name in ('KAIRO_BIN_DIR', 'QS_STATE_DIR'):
                env.pop(name, None)
            # Force the fixture's local-plugin path even if the host has plugins.
            source = (ROOT / 'install.sh').read_text().replace(
                '/usr/share/zsh/plugins/', str(root / 'system-plugins') + '/')
            # Keep relative payload discovery rooted at the actual repository.
            source = source.replace('repo_root=$script_dir',
                                    'repo_root=' + repr(str(ROOT)))
            installer = root / 'install.sh'
            installer.write_text(source)
            command = ['bash', str(installer), '--no-backup', '--install-packages',
                       '--only', 'zsh', '--only', 'fish']
            first = subprocess.run(command, env=env, capture_output=True,
                                   text=True, check=True, timeout=30)
            self.assertNotIn('Changing login shell', first.stdout)
            self.assertNotIn('Fisher', first.stdout)
            self.assertEqual((home / '.zshrc').read_bytes(),
                             (ROOT / '.config/zsh/.zshrc').read_bytes())
            for shell in ('zsh', 'fish'):
                for file in (ROOT / '.config' / shell).rglob('*'):
                    if file.is_file():
                        self.assertEqual(file.read_bytes(), (home / '.config' / shell /
                                         file.relative_to(ROOT / '.config' / shell)).read_bytes())
                self.assertTrue((home / f'.config/starship/{shell}.toml').is_file())
            calls = (root / 'git-calls').read_text()
            self.assertEqual(calls.count('clone '), 5)
            self.assertEqual(calls.count('reset --hard'), 4)
            self.assertTrue((home / '.local/share/zsh/plugins/forgit/forgit.plugin.zsh').is_file())
            self.assertFalse((home / '.config/fish/fish_plugins').exists())
            self.assertFalse((home / '.dotfiles-backup').exists())
            # A repeat preserves existing plugins and user prompt overrides.
            (home / '.config/starship/fish.toml').write_text('# personal prompt\n')
            subprocess.run(command, env=env, capture_output=True,
                           text=True, check=True, timeout=30)
            self.assertEqual((root / 'git-calls').read_text(), calls)
            self.assertEqual((home / '.config/starship/fish.toml').read_text(), '# personal prompt\n')
            self.assertFalse((home / '.dotfiles-backup').exists())


if __name__ == '__main__':
    unittest.main()
