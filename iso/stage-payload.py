#!/usr/bin/env python3
"""Stage repository sources without copying ignored machine state or build files."""
from pathlib import Path
import shutil
import subprocess
import sys

repo, destination = map(lambda value: Path(value).resolve(), sys.argv[1:])
files = subprocess.check_output(['git', '-C', str(repo), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']).decode().split('\0')
# New ISO sources are included before the first commit as well.
files += [str(path.relative_to(repo)) for path in (repo / 'iso').rglob('*') if path.is_file()]
for relative in sorted(set(filter(None, files))):
    relative_path = Path(relative)
    # Keep generated inputs/outputs out of the live root even when a build
    # directory is accidentally committed or the checkout's ignore rules differ.
    if relative_path.parts and relative_path.parts[0] in {'.build', 'out'}:
        continue
    source = repo / relative_path
    if source.is_symlink():
        raise ValueError(f'Refusing to bundle a source symlink: {relative}')
    if not source.is_file():
        continue
    target = destination / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
revision = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
(destination / 'BUILD-REVISION').write_text(revision + '\nIncludes working-tree changes at build time.\n')
