#!/usr/bin/env bash
set -Eeuo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=''
dry_run=false
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --destdir)
            [[ $# -ge 2 && $2 == /* && $2 != / ]] || { echo 'Use --destdir /absolute/staging/path' >&2; exit 2; }
            root=${2%/}; shift 2 ;;
        -h|--help) echo 'Usage: install.sh [--dry-run] [--destdir /absolute/staging/path]'; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
payload="$source_dir/themes/lone"
files=(LICENSE lone.plymouth lone.script)
for ((i=0; i<64; i++)); do files+=("progress-$i.png"); done
for file in "${files[@]}"; do
    [[ -r $payload/$file ]] || { printf 'Missing Lone theme file: %s\n' "$file" >&2; exit 1; }
done
target="$root/usr/share/plymouth/themes/lone"
conf="$root/etc/plymouth/plymouthd.conf"
if $dry_run; then
    printf 'Install Lone -> %s\nSelect Theme=lone -> %s\n' "$target" "$conf"
    echo 'Rebuild initramfs with mkinitcpio if available (live installs only).'
    echo 'Requires the Plymouth initramfs hook and quiet splash kernel parameters; boot configuration is not rewritten.'
    exit 0
fi
command -v python3 >/dev/null || { echo 'Python 3 is required.' >&2; exit 1; }
if [[ -z $root ]]; then
    command -v plymouth-set-default-theme >/dev/null || { echo 'Install Plymouth first (--install-packages).' >&2; exit 1; }
    if ((EUID != 0)); then exec sudo -- bash "$source_dir/install.sh"; fi
fi
# Temporary recovery snapshot, following Kairo's transactional installation model.
snapshot=$(mktemp -d)
changed=false
rebuilding=false
cleanup() {
    local status=$?
    trap - EXIT
    if ((status != 0)) && $changed; then
        rm -rf -- "$target"
        rm -f -- "$conf"
        if [[ -e $snapshot/theme || -L $snapshot/theme ]]; then cp -a -- "$snapshot/theme" "$target"; fi
        if [[ -e $snapshot/conf || -L $snapshot/conf ]]; then cp -a -- "$snapshot/conf" "$conf"; fi
        if $rebuilding; then
            mkinitcpio -P || echo 'Initramfs recovery failed; repair it before rebooting.' >&2
        fi
        echo 'Plymouth theme/config restored after installation failure.' >&2
    fi
    rm -rf -- "$snapshot"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ -e $target || -L $target ]]; then cp -a -- "$target" "$snapshot/theme"; fi
if [[ -e $conf || -L $conf ]]; then cp -a -- "$conf" "$snapshot/conf"; fi
install -d -m 755 -- "$(dirname "$target")" "$(dirname "$conf")"
changed=true
rm -rf -- "$target"
install -d -m 755 -- "$target"
for file in "${files[@]}"; do install -m 644 -- "$payload/$file" "$target/$file"; done
python3 - "$conf" <<'PY'
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
lines = [line + '\n' for line in p.read_text().splitlines()] if p.exists() else []
section = ''
out = []
found = False
for line in lines:
    match = re.match(r'\s*\[([^]]+)\]', line)
    if match:
        section = match[1]
        out.append(line)
        if section == 'Daemon':
            out.append('Theme=lone\n')
            found = True
        continue
    if section == 'Daemon' and re.match(r'\s*Theme\s*=', line):
        continue
    out.append(line)
if not found:
    out.append('\n[Daemon]\nTheme=lone\n')
# Replace a symlink itself, never write through it to an unrelated configuration.
if p.is_symlink():
    p.unlink()
p.write_text(''.join(out))
PY
chmod 644 "$conf"
if [[ -z $root ]]; then
    if command -v mkinitcpio >/dev/null; then
        rebuilding=true
        mkinitcpio -P
        rebuilding=false
    else
        echo 'Rebuild your initramfs with your distribution tooling before rebooting.'
    fi
    echo 'Ensure the Plymouth hook is configured before encrypt/sd-encrypt, and quiet splash is in your kernel parameters.'
fi
printf 'Installed and selected Lone. Bootloader configuration was not changed.\n'
