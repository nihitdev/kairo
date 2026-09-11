#!/usr/bin/env bash

set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_file_contains() {
    local file=$1 text=$2
    grep -Fq -- "$text" "$file" || fail "$file does not contain: $text"
}

assert_count() {
    local expected=$1 file=$2 text=$3 actual
    actual=$(grep -Fc -- "$text" "$file" || true)
    [[ $actual == "$expected" ]] || fail "expected $expected occurrences of '$text' in $file, got $actual"
}

run_preservation_test() {
    local home="$test_root/preserve"
    mkdir -p "$home/.ssh"
    printf '[user]\n    name = Existing User\n[custom]\n    value = retained\n' >"$home/.gitconfig"
    printf 'Host existing.example\n    User existing\n' >"$home/.ssh/config"

    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only git --only ssh >/dev/null

    assert_file_contains "$home/.gitconfig" 'name = Existing User'
    assert_file_contains "$home/.gitconfig" 'value = retained'
    assert_file_contains "$home/.gitconfig" "path = $home/.config/dotfiles/gitconfig"
    assert_file_contains "$home/.ssh/config" 'Host existing.example'
    assert_file_contains "$home/.ssh/config" 'Include ~/.ssh/config.d/*.conf'
    [[ -f $home/.ssh/config.d/dotfiles.conf ]] || fail 'managed SSH fragment was not installed'
    [[ -f $home/.config/dotfiles/gitconfig ]] || fail 'managed Git config was not installed'

    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only git --only ssh >/dev/null
    assert_count 1 "$home/.gitconfig" "path = $home/.config/dotfiles/gitconfig"
    assert_count 1 "$home/.ssh/config" 'Include ~/.ssh/config.d/*.conf'

    mapfile -t backups < <(find "$home/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    [[ ${#backups[@]} -eq 1 ]] || fail 'idempotent repeat created an unnecessary backup run'
    [[ $(stat -c '%a' "$home/.dotfiles-backup") == 700 ]] || fail 'backup parent is not private'
    local backup
    for backup in "${backups[@]}"; do
        [[ $(stat -c '%a' "$home/.dotfiles-backup/$backup") == 700 ]] || fail 'backup run directory is not private'
    done
}

run_normal_install_test() {
    local home="$test_root/normal"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" CI=true \
        "$repo_root/install.sh" >/dev/null
    [[ -f $home/.bashrc ]] || fail 'normal install omitted Bash'
    [[ -f $home/.config/fish/config.fish ]] || fail 'normal install omitted Fish'
    [[ -f $home/.config/nvim/init.lua ]] || fail 'normal install omitted Neovim'
    [[ -f $home/.config/wezterm/wezterm.lua ]] || fail 'normal install omitted WezTerm'
    [[ -f $home/.config/starship/zsh.toml ]] || fail 'normal install omitted Starship'
    [[ ! -e $home/.config/hypr ]] || fail 'normal install unexpectedly selected opt-in Hyprland'
}

run_nvim_payload_test() {
    local home="$test_root/nvim-payload"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only nvim >/dev/null
    [[ -f $home/.config/nvim/lua/plugins/colorscheme.lua ]] || fail 'Neovim colorscheme module missing'
    [[ -f $home/.config/nvim/lua/plugins/editor.lua ]] || fail 'Neovim editor module missing'
    [[ -f $home/.config/nvim/lua/plugins/lsp.lua ]] || fail 'Neovim LSP module missing'
    [[ -f $home/.config/nvim/lua/plugins/ui.lua ]] || fail 'Neovim UI module missing'
    [[ ! -e $home/.config/nvim/lua/plugins/cord.lua ]] || fail 'obsolete Neovim Cord plugin remained'
}

run_traversal_test() {
    local home="$test_root/traversal/home"
    local escaped="$test_root/traversal/escaped"
    mkdir -p "$home" "$escaped"
    printf 'sentinel\n' >"$escaped/sentinel"

    if HOME="$home" XDG_CONFIG_HOME="$home/../../escaped" \
        "$repo_root/install.sh" --only nvim >/dev/null 2>&1; then
        fail 'parent traversal destination was accepted'
    fi
    assert_file_contains "$escaped/sentinel" sentinel
    [[ ! -e $escaped/nvim ]] || fail 'traversal wrote outside HOME'
}

run_symlink_escape_test() {
    local home="$test_root/symlink/home"
    local escaped="$test_root/symlink/escaped"
    mkdir -p "$home" "$escaped"
    ln -s "$escaped" "$home/.config"
    printf 'sentinel\n' >"$escaped/sentinel"

    if HOME="$home" "$repo_root/install.sh" --only nvim >/dev/null 2>&1; then
        fail 'symlink parent escape was accepted'
    fi
    assert_file_contains "$escaped/sentinel" sentinel
    [[ ! -e $escaped/nvim ]] || fail 'symlink escape wrote outside HOME'
}

run_rollback_test() {
    local home="$test_root/rollback/home"
    local fake_bin="$test_root/rollback/bin"
    mkdir -p "$home/.config/bat/themes" "$fake_bin"
    printf 'old config\n' >"$home/.config/bat/config"
    printf 'old theme\n' >"$home/.config/bat/themes/original.theme"
    printf '#!/usr/bin/env bash\nexit 23\n' >"$fake_bin/bat"
    chmod +x "$fake_bin/bat"

    if HOME="$home" XDG_CONFIG_HOME="$home/.config" PATH="$fake_bin:$PATH" \
        "$repo_root/install.sh" --only bat >/dev/null 2>&1; then
        fail 'injected post-install failure unexpectedly succeeded'
    fi
    assert_file_contains "$home/.config/bat/config" 'old config'
    assert_file_contains "$home/.config/bat/themes/original.theme" 'old theme'
    if find "$home" -name '.dotfiles-stage.*' -o -name '.dotfiles-previous.*' | grep -q .; then
        fail 'transaction artifacts remained after rollback'
    fi
}

run_nushell_payload_test() {
    local home="$test_root/nushell"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only nushell >/dev/null
    [[ -f $home/.config/nushell/dotfiles-init/starship.nu ]] || fail 'Starship bootstrap cache missing'
    [[ -f $home/.config/nushell/dotfiles-init/zoxide.nu ]] || fail 'Zoxide bootstrap cache missing'
    assert_file_contains "$home/.config/nushell/config.nu" 'has-command sudo'
}

run_bash_payload_test() {
    local home="$test_root/bash"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only bash >/dev/null
    [[ -f $home/.bashrc ]] || fail 'Bash config missing'
    assert_file_contains "$home/.bashrc" '.config/starship/bash.toml'
}

run_kitty_payload_test() {
    local home="$test_root/kitty"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only kitty >/dev/null
    [[ -f $home/.config/kitty/kitty.conf ]] || fail 'Kitty config missing'
    [[ -f $home/.config/kitty/current-theme.conf ]] || fail 'Kitty theme missing'
    [[ -f $home/.config/kitty/tab.py ]] || fail 'Kitty tab implementation missing'
    [[ -f $home/.config/kitty/tab_bar.py ]] || fail 'Kitty tab entrypoint missing'
    assert_file_contains "$home/.config/kitty/kitty.conf" 'shell /usr/bin/fish'
}

run_fish_payload_test() {
    local home="$test_root/fish"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only fish >/dev/null
    [[ -f $home/.config/fish/config.fish ]] || fail 'Fish config missing'
    [[ -f $home/.config/fish/conf.d/rashin.fish ]] || fail 'Fish conf.d payload missing'
    [[ -f $home/.config/fish/fish_plugins ]] || fail 'Fish plugin manifest missing'
    [[ ! -e $home/.config/fish/fish_variables ]] || fail 'Machine-specific Fish variables were installed'
}

run_fisher_dry_run_test() {
    local home="$test_root/fisher-dry-run" plan
    mkdir -p "$home"
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        "$repo_root/install.sh" --dry-run --install-packages --only fish)
    [[ $plan == *'Install Fisher and sync plugins'* ]] || fail 'Fisher dry-run plan missing'
    [[ ! -e $home/.config/fish ]] || fail 'Fisher dry-run changed the filesystem'
    assert_file_contains "$repo_root/.config/fish/fish_plugins" 'patrickf1/fzf.fish'
    assert_file_contains "$repo_root/.config/fish/fish_plugins" 'jorgebucaran/autopair.fish'
    assert_file_contains "$repo_root/.config/fish/fish_plugins" 'jorgebucaran/replay.fish'
}

run_lazyvim_dry_run_test() {
    local home="$test_root/lazyvim-dry-run" plan
    mkdir -p "$home"
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" CI=true \
        "$repo_root/install.sh" --dry-run --install-packages --only nvim)
    [[ $plan == *'Bootstrap lazy.nvim and sync LazyVim plugins'* ]] ||
        fail 'LazyVim dry-run plan missing'
    [[ ! -e $home/.config/nvim ]] || fail 'LazyVim dry-run wrote Neovim configuration'
    [[ ! -e $home/.local/share/nvim ]] || fail 'LazyVim dry-run downloaded plugin data'
}

run_starship_payload_test() {
    local home="$test_root/starship"
    local plan config
    mkdir -p "$home/.config/starship"
    printf 'old config\n' >"$home/.config/starship/obsolete.toml"

    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --dry-run --only starship)
    [[ $plan == *"Replace $home/.config/starship transactionally"* ]] ||
        fail 'Starship dry-run did not plan a directory replacement'
    assert_file_contains "$home/.config/starship/obsolete.toml" 'old config'

    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only starship >/dev/null
    for config in bash fish nushell zsh; do
        [[ -f $home/.config/starship/$config.toml ]] || fail "Starship $config config missing"
    done
    [[ ! -e $home/.config/starship/obsolete.toml ]] || fail 'stale Starship file survived directory replacement'
    find "$home/.dotfiles-backup" -path '*/.config/starship/obsolete.toml' -type f | grep -q . ||
        fail 'existing Starship directory was not backed up'

    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --only starship >/dev/null
    for config in bash fish nushell zsh; do
        [[ -f $home/.config/starship/$config.toml ]] || fail "Starship $config config missing after repeat install"
    done
}

run_dry_run_immutability_test() {
    local home="$test_root/dry-run"
    local before after
    mkdir -p "$home/.config/starship"
    printf 'sentinel\n' >"$home/.config/starship/sentinel"
    before=$(find "$home" -printf '%P|%y|%s\n' | sort)
    HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        "$repo_root/install.sh" --dry-run --install-packages \
        --only yazi --only broot --only starship >/dev/null
    after=$(find "$home" -printf '%P|%y|%s\n' | sort)
    [[ $before == "$after" ]] || fail 'dry-run changed the filesystem'
    [[ ! -e $home/.dotfiles-backup ]] || fail 'dry-run created a backup directory'
}

run_dry_run_without_optional_generators_test() {
    local home="$test_root/dry-run-no-generators"
    mkdir -p "$home"
    command() {
        if [[ $1 == -v && ($2 == starship || $2 == zoxide) ]]; then
            return 1
        fi
        builtin command "$@"
    }
    export -f command
    HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        "$repo_root/install.sh" --dry-run --only nushell >/dev/null ||
        fail 'Nushell dry-run failed when optional cache generators were unavailable'
    unset -f command
}

run_no_backup_test() {
    local home="$test_root/no-backup"
    mkdir -p "$home/.config/nvim"
    printf 'old\n' >"$home/.config/nvim/old"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --no-backup --only nvim >/dev/null
    [[ -f $home/.config/nvim/init.lua ]] || fail '--no-backup install failed'
    [[ ! -e $home/.dotfiles-backup ]] || fail '--no-backup created backups'
}

run_selector_validation_test() {
    local home="$test_root/selectors" plan
    mkdir -p "$home"
    if HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --dry-run --only invalid-module >/dev/null 2>&1; then
        fail 'invalid component was accepted'
    fi
    if "$repo_root/install.sh" --dry-run --profile invalid-profile >/dev/null 2>&1; then
        fail 'invalid package profile was accepted'
    fi
    if "$repo_root/install.sh" --dry-run --aur-helper invalid-helper >/dev/null 2>&1; then
        fail 'invalid AUR helper was accepted'
    fi
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        "$repo_root/install.sh" --dry-run --only yazi --only broot --only starship)
    [[ $plan == *'Install yazi'* && $plan == *'Install broot'* && $plan == *'Install starship'* ]] ||
        fail 'multiple --only selectors were not honored'
    [[ $plan != *$'\033['* ]] || fail 'non-interactive output contains terminal escape sequences'
}

run_package_profile_dry_run_test() {
    local home="$test_root/package-profile/home" fake_bin="$test_root/package-profile/bin" plan before after
    mkdir -p "$home" "$fake_bin"
    printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/pacman"
    chmod +x "$fake_bin/pacman"
    before=$(find "$home" -printf '%P|%y|%s\n' | sort)
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true PATH="$fake_bin:$PATH" \
        "$repo_root/install.sh" --dry-run --profile core-build --profile cpp --profile rust \
        --aur-helper paru --enable-chaotic-aur --only nvim)
    after=$(find "$home" -printf '%P|%y|%s\n' | sort)
    [[ $before == "$after" ]] || fail 'package-profile dry-run changed the filesystem'
    [[ $plan == *'Trust and locally sign Chaotic-AUR key'* || $plan == *'Chaotic-AUR is already enabled'* ]] || fail 'Chaotic-AUR dry-run plan missing'
    [[ $plan == *'Run sudo pacman -S --needed'* ]] || fail 'toolchain package plan missing'
    [[ $plan == *'wget'* ]] || fail 'core-build profile omitted wget'
}

run_gpu_driver_dry_run_test() {
    local home="$test_root/gpu-dry-run" before after plan
    mkdir -p "$home"
    before=$(find "$home" -printf '%P|%y|%s\n' | sort)
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        "$repo_root/install.sh" --dry-run --install-gpu-drivers --only nvim)
    after=$(find "$home" -printf '%P|%y|%s\n' | sort)
    [[ $before == "$after" ]] || fail 'GPU driver dry-run changed the filesystem'
    assert_file_contains "$repo_root/install.sh" 'sudo -v'
    [[ $plan == *'Installing packages'* ]] || fail 'GPU driver plan omitted package stage'
}

run_missing_optional_source_test() {
    local home="$test_root/missing-source/home"
    local source="$test_root/missing-source/source"
    mkdir -p "$home" "$source/.config/nvim"
    cp "$repo_root/install.sh" "$source/install.sh"
    printf 'return {}\n' >"$source/.config/nvim/init.lua"
    local output
    output=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        bash "$source/install.sh" --dry-run --only bash)
    [[ $output == *'Skipped: bash'* ]] || fail 'missing optional Bash payload was not reported as skipped'
}

run_shell_starship_reference_test() {
    assert_file_contains "$repo_root/.config/bash/.bashrc" '$HOME/.config/starship/bash.toml'
    assert_file_contains "$repo_root/.config/fish/config.fish" '$HOME/.config/starship/fish.toml'
    assert_file_contains "$repo_root/.config/nushell/config.nu" '/starship/nushell.toml'
    assert_file_contains "$repo_root/.config/oh-my-zsh/.zshrc" '$HOME/.config/starship/zsh.toml'
    if grep -R -E --exclude-dir=.git '(\.config/starship\.toml|starship/starship\.toml)' "$repo_root" >/dev/null; then
        fail 'stale single-file Starship path remains'
    fi
}

run_signal_cleanup_static_test() {
    assert_file_contains "$repo_root/install.sh" 'trap handle_interrupt INT TERM'
    assert_file_contains "$repo_root/install.sh" 'exit 130'
    assert_file_contains "$repo_root/.config/scripts/install-ui.sh" "printf '\\033[?25h'"
    assert_file_contains "$repo_root/.config/scripts/install-ui.sh" "printf '\\033[?1049l'"
}

run_remote_verification_test() {
    local home="$test_root/remote/home"
    local script_copy="$test_root/remote/install.sh"
    mkdir -p "$home"
    cp "$repo_root/install.sh" "$script_copy"
    local output
    output=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        bash "$script_copy" --dry-run)
    [[ $output == *'Planned:'* ]] || fail 'remote clone bootstrap did not produce an install plan'
    [[ -d $home/kairo/.git ]] || fail 'remote bootstrap did not clone Kairo under HOME'
    [[ $output == *"Install starship -> $home/.config/starship"* ]] ||
        fail 'remote clone bootstrap omitted current Starship payloads'

    output=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" CI=true \
        bash -s -- --dry-run --only nvim <"$script_copy")
    [[ $output == *'Planned: nvim'* ]] || fail 'stdin bootstrap did not produce an install plan'
}

run_static_security_defaults_test() {
    grep -Fqx -- '--color=auto' "$repo_root/.config/bat/config" || fail 'Bat does not use automatic color mode'
    if grep -Fq '~/.config/fastfetch/ascii.txt' "$repo_root/.config/fastfetch/config.jsonc"; then
        fail 'Fastfetch config still hard-codes ~/.config'
    fi
    local license
    for license in "$repo_root"/.config/yazi/plugins/*.yazi/LICENSE; do
        [[ $(sha256sum "$license" | cut -d' ' -f1) == 06a2b04a7ed4f030a87d10b884fc1a2215c5e91b371f69dfe173448e834f3752 ]] ||
            fail "unexpected vendored license content: $license"
    done
}

run_all_selector_test() {
    local home="$test_root/all-selector"
    mkdir -p "$home"
    local plan
    plan=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --dry-run --only all)
    [[ $plan == *'Install kitty'* ]] || fail '--only all did not select Kitty'
    [[ $plan == *'Install wezterm'* ]] || fail '--only all did not select WezTerm'
    [[ $plan == *'Install fish'* ]] || fail '--only all did not select Fish'
    [[ $plan == *'Install nvim'* ]] || fail '--only all did not select Neovim'
}

run_specific_selector_test() {
    local home="$test_root/specific-selector"
    local component
    mkdir -p "$home"
    for component in bash zsh nushell git lazygit broot nvim yazi fastfetch \
        oh-my-posh starship atuin bat cava ssh kitty fish wezterm; do
        HOME="$home" XDG_CONFIG_HOME="$home/.config" \
            "$repo_root/install.sh" --dry-run --only "$component" >/dev/null ||
            fail "--only rejected supported component: $component"
    done
}

run_hypr_rice_payload_test() {
    local home="$test_root/hypr-rice"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        "$repo_root/install.sh" --no-backup --only hypr >/dev/null
    [[ -f $home/.config/hypr/hyprland.lua ]] || fail 'Hyprland rice payload was not installed'
    [[ -f $home/.config/waybar/style.css ]] || fail 'Waybar rice payload was not installed with Hyprland'
    cmp -s "$repo_root/.config/waybar/style.css" "$home/.config/waybar/style.css" ||
        fail 'installed Waybar rice differs from selected branch'
}

run_wezterm_payload_test() {
    local home="$test_root/wezterm" config
    config="$home/custom-config"
    mkdir -p "$home"
    HOME="$home" XDG_CONFIG_HOME="$config" \
        "$repo_root/install.sh" --only wezterm >/dev/null
    diff -r "$repo_root/.config/wezterm" "$config/wezterm" || fail 'WezTerm payload differs'
    [[ ! -e $home/.wezterm.lua ]] || fail 'legacy WezTerm config was created'
    HOME="$home" XDG_CONFIG_HOME="$config" \
        "$repo_root/install.sh" --only wezterm >/dev/null
    [[ ! -e $home/.dotfiles-backup ]] || fail 'unchanged WezTerm created a backup'

    local legacy_home="$test_root/wezterm-legacy" output
    mkdir -p "$legacy_home"
    printf 'return {}\n' >"$legacy_home/.wezterm.lua"
    output=$(HOME="$legacy_home" XDG_CONFIG_HOME="$legacy_home/.config" \
        "$repo_root/install.sh" --only wezterm)
    [[ $output == *'WezTerm deployment skipped'* ]] || fail 'legacy conflict was not reported'
    [[ $output == *'Skipped: wezterm'* ]] || fail 'WezTerm skip was missing from summary'
    [[ ! -e $legacy_home/.config/wezterm ]] || fail 'competing XDG config was created'
    assert_file_contains "$legacy_home/.wezterm.lua" 'return {}'
}

run_wezterm_payload_test
run_normal_install_test
run_nvim_payload_test
run_preservation_test
run_traversal_test
run_symlink_escape_test
run_rollback_test
run_bash_payload_test
run_nushell_payload_test
run_kitty_payload_test
run_fish_payload_test
run_fisher_dry_run_test
run_lazyvim_dry_run_test
run_starship_payload_test
run_dry_run_immutability_test
run_dry_run_without_optional_generators_test
run_no_backup_test
run_selector_validation_test
run_package_profile_dry_run_test
run_gpu_driver_dry_run_test
run_missing_optional_source_test
run_shell_starship_reference_test
run_signal_cleanup_static_test
run_remote_verification_test
run_static_security_defaults_test
run_all_selector_test
run_specific_selector_test
run_hypr_rice_payload_test
bash "$repo_root/.config/tests/test-kairo-shell.sh"
printf 'Linux installer safety tests passed.\n'
