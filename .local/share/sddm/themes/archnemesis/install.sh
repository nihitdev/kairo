#!/usr/bin/env bash
set -euo pipefail
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dry_run=false
root=''
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --destdir)
            [[ $# -ge 2 && $2 == /* && $2 != / ]] || { echo 'Use --destdir /absolute/staging/path' >&2; exit 2; }
            root="${2%/}"; shift 2 ;;
        --help|-h)
            echo 'Usage: install.sh [--dry-run] [--destdir /absolute/staging/path]'
            echo 'Install and select the theme. --destdir stages files without sudo or runtime dependency checks.'
            exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
files=(Main.qml metadata.desktop theme.conf background.png preview.png)
for file in "${files[@]}"; do
    [[ -r "$source_dir/$file" ]] || { printf 'Missing theme file: %s\n' "$file" >&2; exit 1; }
done
command -v python3 >/dev/null || { echo 'Python 3 is required.' >&2; exit 1; }
target="$root/usr/share/sddm/themes/archnemesis"
conf="$root/etc/sddm.conf.d/zz-archnemesis.conf"
if $dry_run; then
    printf 'Copy theme -> %s\nSelect theme -> %s\nBack up existing theme and SDDM configuration.\nNo services will be enabled or restarted.\n' "$target" "$conf"
    exit 0
fi
if [[ -z $root ]]; then
    command -v sddm-greeter-qt6 >/dev/null || { echo 'Install SDDM with its Qt 6 greeter first. See README.md.' >&2; exit 1; }
    if (( EUID != 0 )); then exec sudo -- bash "$source_dir/install.sh"; fi
fi
backup="$root/var/backups/sddm-archnemesis/$(date +%Y%m%d-%H%M%S)-$$"
install -d -m 755 "$backup" "$root/etc/sddm.conf.d" "$(dirname "$target")"
if [[ -e "$target" ]]; then cp -a "$target" "$backup/theme"; fi
if [[ -f "$conf" ]]; then cp -a "$conf" "$backup/theme.conf"; fi
if [[ -f "$root/etc/sddm.conf" ]]; then cp -a "$root/etc/sddm.conf" "$backup/sddm.conf"; fi
# Mark a complete snapshot before making any live changes.
printf 'archnemesis-v1\n' > "$backup/snapshot"
restore_on_error() {
    local status=$?
    trap - ERR
    local -a rollback_args=("$backup")
    if [[ -n $root ]]; then rollback_args+=(--destdir "$root"); fi
    bash "$source_dir/rollback.sh" "${rollback_args[@]}" || true
    exit "$status"
}
trap restore_on_error ERR
install -d -m 755 "$target"
for file in "${files[@]}"; do install -m 644 "$source_dir/$file" "$target/$file"; done
if [[ -f "$root/etc/sddm.conf" ]]; then
    # The main configuration overrides drop-ins, including ThemeDir.
    python3 - "$root/etc/sddm.conf" <<'PY'
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
section = ''
lines = []
values = {'Current': 'archnemesis', 'ThemeDir': '/usr/share/sddm/themes'}
for line in p.read_text().splitlines(keepends=True):
    match = re.match(r'\s*\[([^]]+)\]', line)
    if match:
        section = match[1]
    setting = re.match(r'\s*(Current|ThemeDir)\s*=', line)
    if section == 'Theme' and setting:
        key = setting[1]
        line = f'{key}={values[key]}\n'
    lines.append(line)
p.write_text(''.join(lines))
PY
fi
printf '[Theme]\nCurrent=archnemesis\nThemeDir=/usr/share/sddm/themes\n' > "$conf"
chmod 644 "$conf"
trap - ERR
printf 'Installed ARCHNEMESIS. No services were enabled or restarted.\nBackup: %s\n' "$backup"
printf 'Rollback: bash %q %q' "$source_dir/rollback.sh" "$backup"
if [[ -n $root ]]; then printf ' --destdir %q' "$root"; fi
printf '\n'
