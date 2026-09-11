#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

fixture="$test_root/release"
mkdir -p "$fixture"/{bin,src/assets/applications,config/kairo,compositors,install} "$test_root/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture/bin/kairo"
cp "$fixture/bin/kairo" "$fixture/bin/kairod"
cp "$fixture/bin/kairo" "$fixture/install/uninstall.sh"
printf '{"default":true}\n' > "$fixture/config/kairo/settings.json"
printf '2.2.0-beta.1\n' > "$fixture/version.txt"
for name in LICENSE UPSTREAM CHANGELOG README; do printf '%s\n' "$name" > "$fixture/$name.md"; done
printf '[Desktop Entry]\nExec=kairo\n' > "$fixture/src/assets/applications/kairo.desktop"
printf '<svg/>\n' > "$fixture/src/assets/kairo-logo.svg"

cat > "$test_root/bin/git" <<'MOCK'
#!/usr/bin/env bash
set -eu
if [[ $1 == clone ]]; then
    printf 'clone\n' >> "$KAIRO_TEST_CALLS"
    [[ ${KAIRO_TEST_FAIL_CLONE:-false} != true ]] || exit 1
    cp -a "$KAIRO_TEST_FIXTURE" "${@: -1}"
elif [[ $1 == -C && $3 == rev-parse ]]; then
    printf '%s\n' "${KAIRO_TEST_COMMIT:-64420cb38748b406608af95b2252f60958a8e5a9}"
else
    exit 1
fi
MOCK
real_cp=$(command -v cp)
cat > "$test_root/bin/cp" <<'MOCK'
#!/usr/bin/env bash
set -eu
if [[ ${KAIRO_TEST_FAIL_ICON:-false} == true && $* == *'/src/assets/kairo-logo.svg'* ]]; then
    exit 1
fi
exec "$KAIRO_TEST_CP" "$@"
MOCK
chmod +x "$test_root/bin/"*
export KAIRO_TEST_FIXTURE="$fixture" KAIRO_TEST_CALLS="$test_root/calls" KAIRO_TEST_CP="$real_cp"

run_install() {
    local test_home=$1
    shift
    HOME="$test_home" XDG_CONFIG_HOME="$test_home/config" XDG_DATA_HOME="$test_home/data" \
        XDG_STATE_HOME="$test_home/state" XDG_CACHE_HOME="$test_home/cache" \
        KAIRO_BIN_DIR="$test_home/bin" QS_STATE_DIR="$test_home/state/kairo" \
        PATH="$test_root/bin:$PATH" CI=true "$repo_root/install.sh" "$@"
}

home="$test_root/home with ' quote"
mkdir -p "$home"
run_install "$home" --dry-run --only hypr --only kairo-shell > "$test_root/plan"
[[ ! -e $test_root/calls && -z $(ls -A "$home") ]] || fail 'dry-run wrote files or fetched the release'
grep -Fq 'Skip Waybar deployment' "$test_root/plan" || fail 'dry-run omitted Waybar decision'

mkdir -p "$home/config/kairo" "$home/config/waybar"
printf '{"personal":true}\n' > "$home/config/kairo/settings.json"
printf 'retain\n' > "$home/config/waybar/sentinel"
run_install "$home" --only hypr --only kairo-shell > "$test_root/install"
[[ -x $home/data/kairo/bin/kairod && -L $home/bin/kairod ]] || fail 'shell or launcher missing'
[[ $(readlink "$home/bin/kairo") == "$home/data/kairo/bin/kairo" ]] || fail 'incorrect launcher target'
grep -Fq 'personal' "$home/config/kairo/settings.json" || fail 'existing settings replaced'
[[ -f $home/config/waybar/sentinel ]] || fail 'existing Waybar config removed'
grep -Fq 'kairod' "$home/config/hypr/hyprland.lua" || fail 'Hyprland startup not integrated'
if grep -Fq 'hl.exec_cmd("waybar")' "$home/config/hypr/hyprland.lua"; then fail 'Waybar startup remained'; fi
if command -v luac >/dev/null 2>&1; then luac -p "$home/config/hypr/hyprland.lua"; fi
[[ ! -d $home/data/kairo/.git ]] || fail 'Git metadata deployed'
cmp "$fixture/LICENSE.md" "$home/data/kairo/src/LICENSE.md" || fail 'license not preserved'
run_install "$home" --only hypr --only kairo-shell > "$test_root/repeat"
[[ ! -e $home/.dotfiles-backup ]] || fail 'repeat installation created unnecessary backups'

for case_name in clone pin rollback conflict unmanaged escape; do
    home="$test_root/$case_name"
    mkdir -p "$home/config/hypr"
    printf 'original\n' > "$home/config/hypr/sentinel"
    case "$case_name" in
        clone) export KAIRO_TEST_FAIL_CLONE=true ;;
        pin) export KAIRO_TEST_COMMIT=incorrect ;;
        rollback) export KAIRO_TEST_FAIL_ICON=true ;;
        conflict) mkdir -p "$home/bin"; printf 'user launcher\n' > "$home/bin/kairo" ;;
        unmanaged) mkdir -p "$home/data/kairo"; printf 'user data\n' > "$home/data/kairo/sentinel" ;;
        escape) ln -s "$test_root" "$home/data" ;;
    esac
    if run_install "$home" --only hypr --only kairo-shell > "$test_root/$case_name.log" 2>&1; then
        fail "$case_name unexpectedly succeeded"
    fi
    unset KAIRO_TEST_FAIL_CLONE KAIRO_TEST_COMMIT KAIRO_TEST_FAIL_ICON
    [[ $(cat "$home/config/hypr/sentinel") == original ]] || fail "$case_name did not preserve Hyprland"
    [[ ! -e $home/bin/kairod && ! -e $home/config/kairo/settings.json ]] || fail "$case_name left a partial install"
    if [[ $case_name == clone || $case_name == pin || $case_name == rollback ]]; then
        [[ ! -e $home/data/kairo && ! -e $home/state/kairo/version ]] || fail "$case_name left shell data or version state"
    fi
    if [[ $case_name == unmanaged ]]; then
        grep -Fq 'user data' "$home/data/kairo/sentinel" || fail 'unmanaged data replaced'
    fi
    if [[ $case_name == conflict ]]; then
        grep -Fq 'user launcher' "$home/bin/kairo" || fail 'unrelated launcher replaced'
    fi
done

home="$test_root/shell-only"
mkdir -p "$home"
run_install "$home" --only kairo-shell > "$test_root/shell-only.log"
[[ ! -e $home/config/hypr && -f $home/config/kairo/settings.json ]] || fail 'shell-only selection changed Hyprland or omitted settings'
printf 'Kairo Shell integration tests passed.\n'
