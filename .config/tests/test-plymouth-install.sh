#!/usr/bin/env bash
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
helper="$repo_root/.local/share/plymouth/install.sh"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
root="$scratch/staging root"
bash "$helper" --dry-run --destdir "$root" >/dev/null
[[ ! -e $root ]] || fail 'dry-run wrote files'
bash "$helper" --destdir "$root" >/dev/null
diff -r "$repo_root/.local/share/plymouth/themes/lone" "$root/usr/share/plymouth/themes/lone"
grep -qx 'Theme=lone' "$root/etc/plymouth/plymouthd.conf"
[[ $(find "$root/usr/share/plymouth/themes" -mindepth 1 -maxdepth 1 -type d | wc -l) == 1 ]] || fail 'extra themes installed'
printf '[Daemon]\nTheme=old\nShowDelay=2\n[Other]\nTheme=untouched\n' > "$root/etc/plymouth/plymouthd.conf"
bash "$helper" --destdir "$root" >/dev/null
grep -qx 'ShowDelay=2' "$root/etc/plymouth/plymouthd.conf"
grep -qx 'Theme=untouched' "$root/etc/plymouth/plymouthd.conf"
cp "$root/etc/plymouth/plymouthd.conf" "$scratch/expected"
bash "$helper" --destdir "$root" >/dev/null
cmp "$scratch/expected" "$root/etc/plymouth/plymouthd.conf"
# Fail after copying the payload and editing the config; restore both exactly.
cp -a "$root/usr" "$scratch/expected-usr"
mkdir "$scratch/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$scratch/bin/chmod"
chmod +x "$scratch/bin/chmod"
if PATH="$scratch/bin:$PATH" bash "$helper" --destdir "$root" > "$scratch/failure.log" 2>&1; then
    fail 'injected failure succeeded'
fi
cmp "$scratch/expected" "$root/etc/plymouth/plymouthd.conf"
diff -r "$scratch/expected-usr" "$root/usr"
mkdir "$scratch/home"
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/home/.local/share" \
    XDG_STATE_HOME="$scratch/home/.local/state" XDG_CACHE_HOME="$scratch/home/.cache" CI=true \
    bash "$repo_root/install.sh" --dry-run --only plymouth > "$scratch/plan"
grep -q 'Planned: plymouth' "$scratch/plan"
grep -q '/usr/share/plymouth/themes/lone' "$scratch/plan"
[[ -z $(find "$scratch/home" -mindepth 1 -print -quit) ]] || fail 'module dry-run wrote files'
printf 'Plymouth payload, selection, idempotence, rollback and module dry-run tests passed.\n'
