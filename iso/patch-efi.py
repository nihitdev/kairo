#!/usr/bin/env python3
"""Update the hybrid ISO's embedded FAT boot menu without mounting it."""
from pathlib import Path
import struct
import subprocess
import sys

image, entries = map(Path, sys.argv[1:])
if not image.is_file() or image.is_symlink():
    raise ValueError('Expected a regular ISO output file')
with image.open('rb') as source:
    mbr = source.read(512)
if mbr[510:] != b'\x55\xaa':
    raise ValueError('Missing hybrid MBR')
partitions = [mbr[446 + i * 16:462 + i * 16] for i in range(4)]
efi = [part for part in partitions if part[4] == 0xef]
if len(efi) != 1:
    raise ValueError('Expected exactly one EFI system partition')
start, sectors = struct.unpack_from('<II', efi[0], 8)
if not start or not sectors or (start + sectors) * 512 > image.stat().st_size:
    raise ValueError('EFI partition is outside the ISO')
for entry in sorted(entries.glob('*.conf')):
    subprocess.run(['mcopy', '-o', '-i', f'{image}@@{start * 512}', str(entry),
                    f'::/loader/entries/{entry.name}'], check=True)
print('Updated embedded UEFI boot menu')
