#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
theme="$repo_root/.local/share/sddm/themes/archnemesis"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
root="$scratch/fresh root"
bash "$theme/install.sh" --dry-run --destdir "$root" >/dev/null
[[ ! -e "$root" ]] || fail 'dry-run wrote files'
bash "$theme/install.sh" --destdir "$root" > "$scratch/install.log"
for file in Main.qml metadata.desktop theme.conf background.png preview.png; do
    cmp "$theme/$file" "$root/usr/share/sddm/themes/archnemesis/$file"
done
backup=$(sed -n 's/^Backup: //p' "$scratch/install.log")
bash "$theme/rollback.sh" "$backup" --destdir "$root" >/dev/null
[[ ! -e "$root/usr/share/sddm/themes/archnemesis" ]] || fail 'fresh theme not removed'
[[ ! -e "$root/etc/sddm.conf.d/zz-archnemesis.conf" ]] || fail 'fresh config not removed'

root="$scratch/existing root"
mkdir -p "$root/etc/sddm.conf.d" "$root/usr/share/sddm/themes/archnemesis"
cat > "$root/etc/sddm.conf" <<'CONFIG'
[General]
DisplayServer=wayland
[Theme]
Current=previous
ThemeDir=/opt/custom-themes
[Autologin]
User=
CONFIG
printf '[Theme]\nCurrent=previous\n' > "$root/etc/sddm.conf.d/zz-archnemesis.conf"
printf 'old theme\n' > "$root/usr/share/sddm/themes/archnemesis/Main.qml"
cp -a "$root/etc" "$scratch/expected-etc"
cp -a "$root/usr" "$scratch/expected-usr"
bash "$theme/install.sh" --destdir "$root" > "$scratch/install.log"
grep -q '^Current=archnemesis$' "$root/etc/sddm.conf" || fail 'main override not updated'
grep -q '^ThemeDir=/usr/share/sddm/themes$' "$root/etc/sddm.conf" || fail 'theme directory override not updated'
grep -q '^DisplayServer=wayland$' "$root/etc/sddm.conf" || fail 'display server changed'
backup=$(sed -n 's/^Backup: //p' "$scratch/install.log")
bash "$theme/rollback.sh" "$backup" --destdir "$root" >/dev/null
diff -r "$scratch/expected-etc" "$root/etc"
diff -r "$scratch/expected-usr" "$root/usr"

# Fail after payload installation and config edits; the complete snapshot must return.
mkdir -p "$scratch/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$scratch/bin/chmod"
chmod +x "$scratch/bin/chmod"
if PATH="$scratch/bin:$PATH" bash "$theme/install.sh" --destdir "$root" > "$scratch/failure.log" 2>&1; then
    fail 'injected failure succeeded'
fi
diff -r "$scratch/expected-etc" "$root/etc"
diff -r "$scratch/expected-usr" "$root/usr"
printf 'SDDM install, dry-run, rollback and failure recovery tests passed.\n'

# Main entry point must expose SDDM and preserve zero-write dry-run behavior.
mkdir -p "$scratch/module-home"
HOME="$scratch/module-home" XDG_CONFIG_HOME="$scratch/module-home/.config" \
    XDG_DATA_HOME="$scratch/module-home/.local/share" CI=true \
    bash "$repo_root/install.sh" --dry-run --only sddm > "$scratch/module-plan"
grep -q 'Planned: sddm' "$scratch/module-plan" || fail 'main installer did not select SDDM'
grep -q '/usr/share/sddm/themes/archnemesis' "$scratch/module-plan" || fail 'system theme missing from plan'
[[ -z $(find "$scratch/module-home" -mindepth 1 -print -quit) ]] || fail 'main dry-run wrote files'

# Exercise module dispatch in an isolated repository fixture, never invoking sudo.
fixture="$scratch/module-repo"
mkdir -p "$fixture/.config/scripts" "$fixture/.config/nvim" "$fixture/.local/share/sddm/themes"
: > "$fixture/.config/nvim/init.lua"
cp "$repo_root/install.sh" "$fixture/install.sh"
cp "$repo_root/.config/scripts/install-ui.sh" "$fixture/.config/scripts/install-ui.sh"
cp -a "$theme" "$fixture/.local/share/sddm/themes/archnemesis"
cat > "$fixture/.local/share/sddm/themes/archnemesis/install.sh" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $# == 0 ]]
printf 'module called\n' > "$HOME/sddm-invoked"
MOCK
mkdir -p "$scratch/module-bin"
cat > "$scratch/module-bin/sudo" <<'MOCK'
#!/usr/bin/env bash
[[ $* == -v ]]
MOCK
chmod +x "$scratch/module-bin/sudo"
HOME="$scratch/module-home" XDG_CONFIG_HOME="$scratch/module-home/.config" \
    XDG_DATA_HOME="$scratch/module-home/.local/share" CI=true PATH="$scratch/module-bin:$PATH" \
    bash "$fixture/install.sh" --only sddm > "$scratch/module-install"
[[ -f "$scratch/module-home/sddm-invoked" ]] || fail 'module did not invoke theme installer'
grep -q 'Installed: sddm' "$scratch/module-install" || fail 'module absent from installed summary'
printf 'SDDM main module selection and dispatch tests passed.\n'
