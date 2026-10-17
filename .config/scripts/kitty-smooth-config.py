#!/usr/bin/env python3
"""Change only smooth cursor options in a staged, existing Kitty override."""
from pathlib import Path
import sys

settings = {
    'cursor_trail': '0',
    'cursor_smooth_motion': 'yes',
    'cursor_smooth_motion_factor': '0.2',
    'cursor_smooth_motion_spring': '0.8',
    'cursor_smooth_motion_max_stretch': '3 2',
    'cursor_smooth_motion_antijitter': '50',
}
p = Path(sys.argv[1])
lines = p.read_text().splitlines(keepends=True)
result = []
seen = set()
for line in lines:
    words = line.split()
    key = words[0] if words else ''
    if key in settings:
        line = f'{key} {settings[key]}\n'
        seen.add(key)
    result.append(line)
if result and not result[-1].endswith('\n'):
    result[-1] += '\n'
for key, value in settings.items():
    if key not in seen:
        result.append(f'{key} {value}\n')
# A preserved override may be a symlink: modify the staged file, not its target.
if p.is_symlink():
    p.unlink()
p.write_text(''.join(result))
