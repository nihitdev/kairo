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
mkdir -p "$target/.config/quickshell/other-shell"
printf 'unrelated shell\n' > "$target/.config/quickshell/other-shell/sentinel"
printf 'custom launcher\n' > "$target/.config/rofi/sentinel"
printf 'wallpaper fixture\n' > "$target/Pictures/space & stars.png"
printf '%s\n' "$target/Pictures/space & stars.png" > "$target/.cache/current-wallpaper"
run_install "$target" --dry-run --only hypr > "$test_root/plan"
[[ ! -e $target/.config/hypr ]] || fail 'desktop dry-run wrote config'
[[ ! -e $target/.config/quickshell/wallpaper-picker ]] || fail 'dry-run deployed carousel'
run_install "$target" --only hypr > "$test_root/first"
[[ $(cat "$target/.config/quickshell/other-shell/sentinel") == 'unrelated shell' ]] || fail 'unrelated Quickshell config overwritten'
for file in shell.qml backend.py README.md; do
    cmp "$repo_root/.config/quickshell/wallpaper-picker/$file" "$target/.config/quickshell/wallpaper-picker/$file" || fail 'carousel payload mismatch'
done
[[ -x $target/.config/hypr/scripts/wallpaper-picker-rofi.sh ]] || fail 'Rofi fallback missing'
[[ $(readlink "$target/.config/hypr/current-wallpaper") == "$target/Pictures/space & stars.png" ]] || fail 'saved wallpaper was not preserved'
[[ $(cat "$target/.config/rofi/sentinel") == 'custom launcher' ]] || fail 'custom Rofi was overwritten'
[[ -f $target/.local/share/fonts/archnemesis/Waycat.ttf ]] || fail 'Waycat font missing'
[[ -f $target/.local/share/fonts/archnemesis/Skulltype.ttf ]] || fail 'Skulltype font missing'
[[ -x $target/.local/bin/battery-guardian ]] || fail 'battery guardian missing'
diff -qr "$repo_root/.config/quickshell/hyprland-notifications" "$target/.config/quickshell/hyprland-notifications"
cmp "$repo_root/.config/waybar/config.jsonc" "$target/.config/waybar/config.jsonc"
[[ -r $target/.config/waybar/colors.css && -x $target/.config/waybar/scripts/wallpaper-colors.py ]] || fail 'adaptive Waybar palette payload missing'
grep -Fq '@import "colors.css";' "$target/.config/waybar/style.css" || fail 'palette stylesheet not imported'
grep -Fq 'wallpaper-colors.py' "$target/.config/hypr/scripts/wallpaper-picker-rofi.sh" || fail 'Rofi palette hook missing'
grep -Fq 'wallpaper-colors.py' "$target/.config/quickshell/wallpaper-picker/backend.py" || fail 'carousel palette hook missing'

run_install "$target" --only hypr > "$test_root/repeat"
! grep -q 'Replace ' "$test_root/repeat" || fail 'desktop reinstall replaced unchanged files'
[[ ! -e $target/.dotfiles-backup ]] || fail '--no-backup created backups'

# A selected live wallpaper must survive reinstall, including embedded media.
printf 'video fixture\n' > "$target/Pictures/live.mp4"
ln -s "$target/Pictures/live.mp4" "$target/.config/hypr/current-live-wallpaper"
run_install "$target" --only hypr >/dev/null
[[ $(readlink "$target/.config/hypr/current-live-wallpaper") == "$target/Pictures/live.mp4" ]] || fail 'live wallpaper link lost'
rm "$target/.config/hypr/current-live-wallpaper"
printf 'embedded video\n' > "$target/.config/hypr/current-live-wallpaper"
run_install "$target" --only hypr >/dev/null
[[ $(cat "$target/.config/hypr/current-live-wallpaper") == 'embedded video' ]] || fail 'embedded live wallpaper lost'

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
grep -Fq "path = $target/.config/hypr/current-wallpaper" "$target/.config/hyprlock/hyprlock.conf" || fail 'stable wallpaper path missing from lock config'
# Without the managed wallpaper, use the cached path and preserve its ampersand.
rm "$target/.config/hypr/current-wallpaper"
HOME="$target" XDG_CONFIG_HOME="$target/.config" PATH="$test_root/mock-bin:$PATH" \
    bash "$target/.config/hypr/scripts/lock.sh"
grep -Fq "path = $target/Pictures/space & stars.png" "$target/.config/hyprlock/hyprlock.conf" || fail 'wallpaper path corrupted in lock config'
rm "$target/.cache/current-wallpaper"
HOME="$target" XDG_CONFIG_HOME="$target/.config" PATH="$test_root/mock-bin:$PATH" \
    bash "$target/.config/hypr/scripts/lock.sh"
grep -q 'color = rgba(25, 23, 36, 1.0)' "$target/.config/hyprlock/hyprlock.conf" || fail 'lock fallback missing'
# A fresh Hyprland install gets the curated images and snow-pine default.
target="$test_root/fresh-desktop"
mkdir -p "$target"
run_install "$target" --dry-run --only hypr > "$test_root/fresh-plan"
[[ ! -e $target/Pictures ]] || fail 'wallpaper dry-run created directories'
grep -Fq 'snow-pine-forest.png' "$test_root/fresh-plan" || fail 'default wallpaper missing from plan'
run_install "$target" --only hypr > "$test_root/fresh-install"
[[ $(readlink "$target/.config/hypr/current-wallpaper") == "$target/Pictures/Wallpapers/snow-pine-forest.png" ]] || fail 'fresh default is not snow-pine-forest'
cmp "$repo_root/.local/share/wallpapers/archnemesis/snow-pine-forest.png" "$target/Pictures/Wallpapers/snow-pine-forest.png"
[[ ! -d $target/Pictures/CozyPixels/.git ]] || fail 'full CozyPixels checkout installed'
expected_wallpapers=$(find "$repo_root/.local/share/wallpapers/archnemesis" -mindepth 1 -maxdepth 1 -type f | wc -l)
[[ $(find "$target/Pictures/Wallpapers" -mindepth 1 -maxdepth 1 -type f | wc -l) == "$expected_wallpapers" ]] || fail "expected exactly $expected_wallpapers wallpaper images"
for added_image in Clouds.jpg Girl-Shooter.png Mahoraga.jpg; do
    [[ -f $target/Pictures/Wallpapers/$added_image ]] || fail "additional wallpaper missing: $added_image"
done
[[ -z $(find "$target/Pictures/Wallpapers" -mindepth 1 -type d -print -quit) ]] || fail 'wallpaper subdirectories installed'
[[ -f $target/Pictures/Wallpapers/snow-desert-sunset.jpg && -f $target/Pictures/Wallpapers/snow-mountain-range.jpg ]] || fail 'downloaded JPG wallpapers missing'
[[ -z $(find "$target/Pictures/Wallpapers" -type f ! -iname '*.png' ! -iname '*.jpg' ! -iname '*.jpeg' ! -iname '*.webp' -print -quit) ]] || fail 'non-image files installed with wallpapers'
while IFS= read -r -d '' image; do
    cmp "$image" "$target/Pictures/Wallpapers/${image##*/}" || fail 'installed wallpaper differs from bundled image'
done < <(find "$repo_root/.local/share/wallpapers/archnemesis" -maxdepth 1 -type f -print0)

# Optional wallpaper installs are offline, preserve personal files, and roll back.
cat > "$test_root/mock-bin/git" <<'MOCK'
#!/usr/bin/env bash
printf 'unexpected Git operation\n' >&2
exit 1
MOCK
cat > "$test_root/mock-bin/cp" <<'MOCK'
#!/usr/bin/env bash
set -eu
if [[ ${FAIL_WALLPAPER_COPY:-false} == true && $* == *snow-night-moon.png* ]]; then
    exit 1
fi
exec "$REAL_CP" "$@"
MOCK
printf '#!/usr/bin/env bash\nexit 1\n' > "$test_root/mock-bin/bat"
chmod +x "$test_root/mock-bin/git" "$test_root/mock-bin/cp" "$test_root/mock-bin/bat"
export REAL_CP
REAL_CP=$(command -v cp)
for scenario in success copy-failure rollback; do
    target="$test_root/wallpapers-$scenario"
    mkdir -p "$target/Pictures/Wallpapers"
    printf 'personal image\n' > "$target/Pictures/Wallpapers/personal.png"
    args=(--only kitty --install-wallpapers)
    [[ $scenario != rollback ]] || args+=(--only bat)
    if PATH="$test_root/mock-bin:$PATH" FAIL_WALLPAPER_COPY="$([[ $scenario == copy-failure ]] && echo true || echo false)" \
        run_install "$target" "${args[@]}" > "$test_root/wallpapers-$scenario.log" 2>&1; then
        [[ $scenario == success ]] || fail "$scenario unexpectedly succeeded"
        [[ -f $target/Pictures/Wallpapers/snow-pine-forest.png ]] || fail 'curated default missing'
        [[ -f "$target/Pictures/Wallpapers/astronaut.png" ]] || fail 'curated cosmic images missing'
        # Existing same-name images are left untouched, including on repeat install.
        printf 'personal replacement\n' > "$target/Pictures/Wallpapers/snow-pine-forest.png"
        PATH="$test_root/mock-bin:$PATH" run_install "$target" "${args[@]}" > "$test_root/wallpapers-repeat.log"
        [[ $(cat "$target/Pictures/Wallpapers/snow-pine-forest.png") == 'personal replacement' ]] || fail 'existing wallpaper overwritten'
        ! grep -q 'Replace ' "$test_root/wallpapers-repeat.log" || fail 'wallpaper reinstall replaced files'
    else
        [[ $scenario != success ]] || fail 'wallpaper installation failed'
        [[ $(find "$target/Pictures/Wallpapers" -type f | wc -l) == 1 ]] || fail 'partial wallpaper files remained after rollback'
        [[ ! -e $target/.config/kitty ]] || fail 'wallpaper failure did not roll back configs'
    fi
    [[ $(cat "$target/Pictures/Wallpapers/personal.png") == 'personal image' ]] || fail 'personal wallpaper lost'
done

# Reject an escaping wallpaper subdirectory before replacing any configs.
target="$test_root/wallpapers-escape"
mkdir -p "$target/Pictures/Wallpapers" "$test_root/wallpaper-outside"
ln -s "$test_root/wallpaper-outside/external.png" "$target/Pictures/Wallpapers/snow-pine-forest.png"
if run_install "$target" --only kitty --install-wallpapers > "$test_root/wallpapers-escape.log" 2>&1; then
    fail 'wallpaper destination escape accepted'
fi
[[ ! -e $target/.config/kitty ]] || fail 'wallpaper preflight failure changed configs'
[[ -z $(find "$test_root/wallpaper-outside" -type f -print -quit) ]] || fail 'wallpaper escaped HOME'
printf 'Desktop installer tests passed.\n'
