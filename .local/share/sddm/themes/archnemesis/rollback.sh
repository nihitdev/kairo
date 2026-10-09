#!/usr/bin/env bash
set -euo pipefail
backup="${1:?Pass the backup directory printed by install.sh}"
shift
root=''
if (($#)); then
    [[ $# == 2 && $1 == --destdir && $2 == /* && $2 != / ]] || exit 2
    root="${2%/}"
fi
[[ "$backup" == "$root/var/backups/sddm-archnemesis/"* && -f "$backup/snapshot" ]] || {
    echo 'Not an ARCHNEMESIS backup.' >&2; exit 1;
}
[[ $(cat "$backup/snapshot") == archnemesis-v1 ]] || exit 1
if [[ -z $root ]] && (( EUID != 0 )); then exec sudo -- bash "$0" "$backup"; fi
conf="$root/etc/sddm.conf.d/zz-archnemesis.conf"
target="$root/usr/share/sddm/themes/archnemesis"
if [[ -f "$backup/theme.conf" ]]; then cp -a "$backup/theme.conf" "$conf"; else rm -f "$conf"; fi
if [[ -f "$backup/sddm.conf" ]]; then cp -a "$backup/sddm.conf" "$root/etc/sddm.conf"; fi
rm -rf -- "$target"
if [[ -e "$backup/theme" ]]; then cp -a "$backup/theme" "$target"; fi
printf 'Previous SDDM configuration and theme restored. No services were restarted.\n'
