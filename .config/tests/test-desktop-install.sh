#!/usr/bin/env bash
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
run_install() {
    local test_home=$1
    shift
    HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" XDG_DATA_HOME="$test_home/.local/share" \
        XDG_STATE_HOME="$test_home/.local/state" XDG_CACHE_HOME="$test_home/.cache" CI=true \
        "$repo_root/install.sh" --no-backup "$@"
}

target="$test_root/home with spaces"
mkdir -p "$target/.config/rofi" "$target/.cache" "$target/Pictures"
printf 'custom launcher\n' > "$target/.config/rofi/sentinel"
printf 'wallpaper fixture\n' > "$target/Pictures/space & stars.png"
printf '%s\n' "$target/Pictures/space & stars.png" > "$target/.cache/current-wallpaper"
run_install "$target" --dry-run --only hypr > "$test_root/plan"
[[ ! -e $target/.config/hypr ]] || fail 'desktop dry-run wrote config'
run_install "$target" --only hypr > "$test_root/first"
[[ $(readlink "$target/.config/hypr/current-wallpaper") == "$target/Pictures/space & stars.png" ]] || fail 'saved wallpaper was not preserved'
[[ $(cat "$target/.config/rofi/sentinel") == 'custom launcher' ]] || fail 'custom Rofi was overwritten'
[[ -f $target/.local/share/fonts/archnemesis/Waycat.ttf ]] || fail 'Waycat font missing'
[[ -f $target/.local/share/fonts/archnemesis/Skulltype.ttf ]] || fail 'Skulltype font missing'
[[ -x $target/.local/bin/battery-guardian ]] || fail 'battery guardian missing'
cmp "$repo_root/.config/swaync/config.json" "$target/.config/swaync/config.json"
cmp "$repo_root/.config/swaync/style.css" "$target/.config/swaync/style.css"
cmp "$repo_root/.config/waybar/config.jsonc" "$target/.config/waybar/config.jsonc"
run_install "$target" --only hypr > "$test_root/repeat"
! grep -q 'Replace ' "$test_root/repeat" || fail 'desktop reinstall replaced unchanged files'
[[ ! -e $target/.dotfiles-backup ]] || fail '--no-backup created backups'

# Also preserve wallpaper data stored directly inside the replaced Hyprland tree.
rm "$target/.config/hypr/current-wallpaper"
printf 'embedded image\n' > "$target/.config/hypr/current-wallpaper"
run_install "$target" --only hypr >/dev/null
[[ ! -L $target/.config/hypr/current-wallpaper ]] || fail 'embedded wallpaper became a dangling link'
[[ $(cat "$target/.config/hypr/current-wallpaper") == 'embedded image' ]] || fail 'embedded wallpaper lost'

target="$test_root/bar-only"
mkdir -p "$target"
run_install "$target" --only waybar >/dev/null
[[ -f $target/.config/waybar/style.css && ! -e $target/.config/hypr && ! -e $target/.config/rofi ]] || fail 'Waybar-only scope incorrect'

target="$test_root/escape"
mkdir -p "$target/.local" "$test_root/outside"
ln -s "$test_root/outside" "$target/.local/share"
if run_install "$target" --only hypr > "$test_root/escape.log" 2>&1; then fail 'font destination escape accepted'; fi
[[ ! -e $target/.config/hypr ]] || fail 'preflight failure changed Hyprland'
[[ ! -e $test_root/outside/fonts ]] || fail 'font preflight wrote outside HOME'
# Lock generation must survive '&' in names and a missing wallpaper, without locking.
mkdir -p "$test_root/mock-bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$test_root/mock-bin/pgrep"
printf '#!/usr/bin/env bash\nexit 0\n' > "$test_root/mock-bin/hyprlock"
chmod +x "$test_root/mock-bin/"*
target="$test_root/home with spaces"
HOME="$target" XDG_CONFIG_HOME="$target/.config" PATH="$test_root/mock-bin:$PATH" \
    bash "$target/.config/hypr/scripts/lock.sh"
grep -Fq "path = $target/Pictures/space & stars.png" "$target/.config/hyprlock/hyprlock.conf" || fail 'wallpaper path corrupted in lock config'
rm "$target/.cache/current-wallpaper" "$target/.config/hypr/current-wallpaper"
HOME="$target" XDG_CONFIG_HOME="$target/.config" PATH="$test_root/mock-bin:$PATH" \
    bash "$target/.config/hypr/scripts/lock.sh"
grep -q 'color = rgba(25, 23, 36, 1.0)' "$target/.config/hyprlock/hyprlock.conf" || fail 'lock fallback missing'
# Wallpaper downloads use a staged checkout and participate in config rollback.
cat > "$test_root/mock-bin/git" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $1 == clone ]] || exit 1
mkdir -p "${@: -1}/.git"
printf 'wallpaper fixture\n' > "${@: -1}/wallpaper.png"
[[ ${FAIL_WALLPAPER_CLONE:-false} != true ]]
MOCK
printf '#!/usr/bin/env bash\nexit 1\n' > "$test_root/mock-bin/bat"
chmod +x "$test_root/mock-bin/git" "$test_root/mock-bin/bat"
for scenario in success clone-failure rollback; do
    target="$test_root/wallpapers-$scenario"
    mkdir -p "$target"
    args=(--only kitty --install-wallpapers)
    [[ $scenario != rollback ]] || args+=(--only bat)
    if PATH="$test_root/mock-bin:$PATH" FAIL_WALLPAPER_CLONE="$([[ $scenario == clone-failure ]] && echo true || echo false)" \
        run_install "$target" "${args[@]}" > "$test_root/wallpapers-$scenario.log" 2>&1; then
        [[ $scenario == success ]] || fail "$scenario unexpectedly succeeded"
        [[ -f $target/Pictures/Wallpapers/CozyPixels/wallpaper.png ]] || fail 'wallpapers missing'
    else
        [[ $scenario != success ]] || fail 'wallpaper installation failed'
        [[ ! -e $target/Pictures/Wallpapers/CozyPixels ]] || fail 'partial wallpaper checkout remained'
        [[ ! -e $target/.config/kitty ]] || fail 'wallpaper failure did not roll back configs'
    fi
done
printf 'Desktop installer tests passed.\n'
