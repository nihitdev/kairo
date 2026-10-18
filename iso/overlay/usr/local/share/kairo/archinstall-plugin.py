"""Bundle Kairo in the selected target without changing disk or account choices."""
from pathlib import Path
import shutil

# Archinstall's loader compares this with its major.minor version.
from archinstall.lib.version import get_version

__archinstall__version__ = float(get_version().rsplit('.', 1)[0])


class Plugin:
    def on_install(self, installation):
        target = Path(installation.target)
        if not target.is_absolute() or target.resolve() == Path('/'):
            raise ValueError('Kairo requires a separate Archinstall target')
        destination = target / 'opt/kairo'
        if destination.exists() or destination.is_symlink():
            raise FileExistsError(f'Refusing to replace {destination}')
        shutil.copytree('/opt/kairo', destination, symlinks=True)
        commands = target / 'usr/local/bin'
        commands.mkdir(parents=True, exist_ok=True)
        shutil.copy2('/usr/local/bin/kairo-setup', commands / 'kairo-setup')
        profiles = target / 'etc/profile.d'
        profiles.mkdir(parents=True, exist_ok=True)
        (profiles / 'kairo.sh').write_text(
            'if [ -t 1 ] && [ "$(id -u)" != 0 ] && [ ! -d "$HOME/.config/hypr" ]; then\n'
            '    printf "\\nKairo is ready. Run kairo-setup to install your desktop and dotfiles.\\n\\n"\n'
            'fi\n'
        )
