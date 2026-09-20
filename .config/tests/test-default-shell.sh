#!/usr/bin/env bash
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir -p "$test_root/bin" "$test_root/home"
cat > "$test_root/bin/chsh" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SHELL_TEST_CALLS"
exit "${SHELL_TEST_STATUS:-0}"
MOCK
cat > "$test_root/bin/getent" <<'MOCK'
#!/usr/bin/env bash
printf 'fixture:x:1000:1000:Fixture:/tmp/fixture:%s\n' "${SHELL_TEST_CURRENT:-/bin/sh}"
MOCK
chmod +x "$test_root/bin/"*
export SHELL_TEST_CALLS="$test_root/calls"
run_install() {
    HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/home/.config" \
        XDG_CACHE_HOME="$test_root/home/.cache" PATH="$test_root/bin:$PATH" CI=true \
        "$repo_root/install.sh" --no-backup --only bash "$@"
}
for invalid in invalid '' /bin/bash; do
    if run_install --default-shell "$invalid" >/dev/null 2>&1; then fail 'invalid shell accepted'; fi
done
if run_install --default-shell >/dev/null 2>&1; then fail 'missing shell value accepted'; fi
for shell in keep bash zsh fish nushell nu; do
    run_install --dry-run --default-shell "$shell" > "$test_root/plan"
    if [[ $shell != keep ]]; then grep -q 'Set default shell' "$test_root/plan" || fail 'shell dry-run missing'; fi
done
[[ ! -e $SHELL_TEST_CALLS && ! -e $test_root/home/.bashrc ]] || fail 'shell dry-run made changes'
run_install >/dev/null
run_install --default-shell keep >/dev/null
[[ ! -e $SHELL_TEST_CALLS ]] || fail 'default/keep called chsh'
run_install --default-shell bash > "$test_root/change"
[[ $(wc -l < "$SHELL_TEST_CALLS") == 1 ]] || fail 'explicit shell selection did not call chsh once'
grep -Eq '^-s /(usr/)?bin/bash$' "$SHELL_TEST_CALLS" || fail 'incorrect chsh arguments'
export SHELL_TEST_CURRENT=/bin/bash
run_install --default-shell bash >/dev/null
[[ $(wc -l < "$SHELL_TEST_CALLS") == 1 ]] || fail 'already-current shell called chsh'
unset SHELL_TEST_CURRENT
export SHELL_TEST_STATUS=1
run_install --default-shell bash > "$test_root/failed"
grep -q 'Could not set bash' "$test_root/failed" || fail 'chsh failure not reported'
[[ -f $test_root/home/.bashrc ]] || fail 'chsh failure discarded successful config install'
printf 'Default shell tests passed (chsh mocked; no account changes).\n'
