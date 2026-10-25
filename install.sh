#!/usr/bin/env bash

# ─────────────────────────────────────────────────────────────────────────────
# Kairo · Arch Linux Dotfiles Installer
# ─────────────────────────────────────────────────────────────────────────────

set -Eeuo pipefail

original_args=("$@")

if [[ $(uname -s) != Linux ]]; then
    printf 'This installer supports Linux only.\n' >&2
    exit 1
fi

dry_run=false
no_backup=false
install_packages=false
interactive=false
non_interactive=false
default_shell=keep
enable_chaotic_aur=false
aur_helper=paru
install_gpu_drivers=false
install_wallpapers=false
rebuild_kitty_smooth=false
sddm_receipt=''
gpu_description='No supported GPU detected'
declare -a only=()
declare -a profiles=()
declare -a installed=()
declare -a already_current=()
declare -a skipped=()
declare -a warnings=()
declare -a missing_official_packages=()
declare -a missing_aur_packages=()
declare -a gpu_packages=()
declare -a transaction_destinations=()
declare -a transaction_previous=()
declare -a transaction_had_previous=()
declare -a transaction_stages=()
transaction_active=false
chaotic_config_changed=false
chaotic_config_backup=''

kairo_shell_version='v2.2.0-beta.1'
kairo_shell_commit='64420cb38748b406608af95b2252f60958a8e5a9'
kairo_shell_repo='https://github.com/nihitdev/kairo-shell.git'

# Runtime packages from the pinned Kairo Shell release.
declare -a kairo_shell_packages=(
    kitty cava zbar pavucontrol alsa-utils wl-clipboard fd qt6-multimedia qt6-5compat ripgrep
    cliphist jq socat inotify-tools pamixer brightnessctl ddcutil acpi iw bluez bluez-utils
    libnotify networkmanager lm_sensors bc matugen pipewire wireplumber pipewire-pulse pipewire-alsa
    libpulse python imagemagick wget file git psmisc ffmpeg fastfetch quickshell unzip
    python-websockets qt6-websockets grim playerctl satty xdg-desktop-portal-gtk slurp wmctrl
    power-profiles-daemon easyeffects nautilus qt5-wayland qt5-quickcontrols qt5-quickcontrols2
    qt5-graphicaleffects qt6-wayland qt5ct qt6ct gpu-screen-recorder wf-recorder adw-gtk-theme
    hyprland xdg-desktop-portal-hyprland ttf-iosevka-nerd curl fzf pciutils fontconfig
)

# Packages used by the shipped desktop scripts, not unrelated application bundles.
declare -a hypr_packages=(
    hyprland hyprpaper hypridle hyprlock awww network-manager-applet
    kitty rofi cliphist wl-clipboard jq libnotify brightnessctl playerctl
    wireplumber xdg-desktop-portal-hyprland qt5-wayland qt6-wayland qt6ct kvantum
    grim slurp procps-ng util-linux ffmpeg matugen quickshell qt6-declarative python-pillow
    ttf-iosevka-nerd ttf-jetbrains-mono-nerd
)
declare -a waybar_packages=(
    waybar python python-pillow ffmpeg jq matugen kitty wireplumber brightnessctl playerctl ttf-jetbrains-mono
    networkmanager bluez bluez-utils bluetui pulsemixer btop cava calcurse yazi rofi libnotify fontconfig ttf-iosevka-nerd
)

# Single module registry: id | label | category | default | package | command | source.
# Keep this embedded so the remote bootstrap remains a standalone script.
declare -a module_names=() module_labels=() module_categories=()
declare -A module_default=() module_package=() module_aur_package=() module_command=()
while IFS='|' read -r name label category selected package executable source; do
    module_names+=("$name")
    module_labels+=("$label")
    module_categories+=("$category")
    module_default[$name]=$selected
    module_command[$name]=$executable
    if [[ $source == aur ]]; then
        module_aur_package[$name]=$package
    else
        module_package[$name]=$package
    fi
done <<'MODULES'
bash|Bash|Shells|true|bash|bash|official
fish|Fish|Shells|true|fish|fish|official
prism|Prism terminal themes|Shells|true||prism|official
nushell|Nushell|Shells|true|nushell|nu|official
zsh|Zsh|Shells|true|zsh|zsh|official
starship|Starship|Shells|true|starship|starship|official
atuin|Atuin|CLI|true|atuin|atuin|official
bat|Bat|CLI|true|bat|bat|official
broot|Broot|CLI|true|broot|broot|official
yazi|Yazi|CLI|true|yazi|yazi|official
lazygit|LazyGit|CLI|true|lazygit|lazygit|official
fastfetch|Fastfetch|CLI|true|fastfetch|fastfetch|official
btop|Btop|CLI|true|btop|btop|official
git|Git|Development|true|git|git|official
nvim|Neovim|Development|true|neovim|nvim|official
kitty|Kitty|Desktop|true|kitty|kitty|official
cava|Cava|Desktop|true|cava|cava|official
ssh|SSH|System|true|openssh|ssh|official
oh-my-posh|Oh My Posh|Shells|true|oh-my-posh-bin|oh-my-posh|aur
hypr|Hyprland|Desktop|true|hyprland|Hyprland|official
kairo-shell|Kairo Shell|Desktop|false||quickshell|official
rofi|Rofi|Desktop|true|rofi|rofi|official
wezterm|WezTerm|Desktop|true|wezterm|wezterm|official
waybar|Waybar|Desktop|true|waybar|waybar|official
sddm|SDDM login theme|System|true|sddm|sddm-greeter-qt6|official
plymouth|Plymouth Lone|System|true|plymouth|plymouth-set-default-theme|official
kitty-smooth|Kitty Smooth|Desktop|true|kitty|kitty|official
MODULES
declare -A installed_package_cache=()
package_cache_loaded=false
declare -a profile_names=(core-build cpp rust python web containers wayland media)
declare -a profile_labels=('Core build tools' 'C / C++' 'Rust' 'Python' 'Web / JavaScript' 'Containers' 'Wayland utilities' 'Media production')
declare -a profile_categories=(Toolchains Toolchains Toolchains Toolchains Toolchains Platform Platform Platform)
declare -A profile_packages=(
    [core-build]='base-devel git curl wget rsync unzip zip jq shellcheck'
    [cpp]='gcc clang cmake ninja meson gdb lldb'
    [rust]='rustup'
    [python]='python python-pip uv'
    [web]='nodejs npm pnpm bun'
    [containers]='podman podman-compose buildah'
    [wayland]='xdg-desktop-portal-hyprland wl-clipboard grim slurp swappy brightnessctl playerctl ddcutil libnotify'
    [media]='pipewire pipewire-pulse wireplumber ffmpeg imagemagick yt-dlp'
)

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run          Show what would change without writing files
  --non-interactive  Skip setup menus; use defaults or --only selections
  --no-backup        Replace existing files without backing them up
  --rebuild-kitty-smooth
                     Rebuild even when the pinned Kitty Smooth build is installed
  --list-modules     Print module metadata as tab-separated rows and exit
  --default-shell NAME
                     Login shell: keep (default), bash, zsh, fish, nushell (or nu)
                     Changes only after a successful install; may prompt for password
  --install-packages Install missing selected packages with pacman and paru/yay
  --profile NAME     Install an optional package profile; repeatable
                     Profiles: core-build cpp rust python web containers wayland media all
  --aur-helper NAME  Use paru (default) or yay for AUR packages
  --enable-chaotic-aur
                     Enable the third-party Chaotic-AUR binary repository
  --install-gpu-drivers
                     Install reviewed Arch drivers for detected GPUs
  --install-wallpapers
                     Install the bundled curated wallpapers (included with Hyprland)
  --only NAME        Install one specific component; repeat for multiple tools
                     Use --only all to install every supported component
  -h, --help         Show this help

Components:
EOF
    printf '  %s all\n' "${module_names[*]}"
}

while (($#)); do
    case "$1" in
        --non-interactive)
            non_interactive=true
            ;;
        --dry-run)
            dry_run=true
            ;;
        --list-modules)
            for index in "${!module_names[@]}"; do
                name=${module_names[index]}
                printf '%s\t%s\t%s\t%s\n' "$name" "${module_labels[index]}" "${module_categories[index]}" "${module_default[$name]}"
            done
            exit 0
            ;;
        --rebuild-kitty-smooth)
            rebuild_kitty_smooth=true
            ;;
        --no-backup)
            no_backup=true
            ;;
        --default-shell)
            [[ $# -ge 2 ]] || { printf 'Missing value for --default-shell\n' >&2; exit 2; }
            default_shell=$2
            [[ $default_shell != nu ]] || default_shell=nushell
            shift
            ;;
        --install-packages)
            install_packages=true
            ;;
        --profile)
            [[ $# -ge 2 ]] || { printf 'Missing value for --profile\n' >&2; exit 2; }
            profiles+=("$2")
            install_packages=true
            shift
            ;;
        --aur-helper)
            [[ $# -ge 2 ]] || { printf 'Missing value for --aur-helper\n' >&2; exit 2; }
            aur_helper=$2
            shift
            ;;
        --enable-chaotic-aur)
            enable_chaotic_aur=true
            install_packages=true
            ;;
        --install-gpu-drivers)
            install_gpu_drivers=true
            install_packages=true
            ;;
        --install-wallpapers)
            install_wallpapers=true
            ;;
        --only)
            [[ $# -ge 2 ]] || { printf 'Missing value for --only\n' >&2; exit 2; }
            only+=("$2")
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

case "$default_shell" in
    keep | bash | zsh | fish | nushell) ;;
    *) printf 'Unsupported default shell: %s\n' "$default_shell" >&2; exit 2 ;;
esac

[[ $aur_helper == paru || $aur_helper == yay ]] || {
    printf 'Unsupported AUR helper: %s (expected paru or yay)\n' "$aur_helper" >&2
    exit 2
}
for profile in "${profiles[@]}"; do
    [[ $profile == all || " ${profile_names[*]} " == *" $profile "* ]] || {
        printf 'Unsupported package profile: %s\n' "$profile" >&2
        exit 2
    }
done
for profile in "${profiles[@]}"; do
    if [[ $profile == all ]]; then
        profiles=("${profile_names[@]}")
        break
    fi
done

valid_components=" ${module_names[*]} all "
for component in "${only[@]}"; do
    if [[ $valid_components != *" $component "* ]]; then
        printf 'Unsupported component: %s\n' "$component" >&2
        exit 2
    fi
done

script_path=${BASH_SOURCE[0]:-}
if [[ -n $script_path ]]; then
    script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
    repo_root=$script_dir
else
    script_dir=''
    repo_root=''
fi
temporary_root=''
stage_root=''
external_root=''

# Local runs load the dependency-free UI immediately. Remote runs hand off to
# the same verified repository snapshot after it has been downloaded.
if [[ -n $script_dir && -f $script_dir/.config/scripts/install-ui.sh ]]; then
    # shellcheck source=.config/scripts/install-ui.sh
    source "$script_dir/.config/scripts/install-ui.sh"
fi
if ! $non_interactive && [[ -t 0 && -t 1 && ${CI:-false} != true && ${#only[@]} -eq 0 ]] &&
    declare -F ui_start >/dev/null; then
    interactive=true
fi

cleanup() {
    local stage
    if declare -F ui_restore >/dev/null; then
        ui_restore
    fi
    if [[ -n $temporary_root && -d $temporary_root ]]; then
        rm -rf -- "$temporary_root"
    fi
    if [[ -n $stage_root && -d $stage_root ]]; then
        rm -rf -- "$stage_root"
    fi
    if [[ -n $external_root && -d $external_root ]]; then
        rm -rf -- "$external_root"
    fi
    for stage in "${transaction_stages[@]}"; do
        if [[ -n $stage && -d $stage ]]; then
            rm -rf -- "$stage"
        fi
    done
}
trap cleanup EXIT

# Remote quick start: clone/update ~/kairo, then run the normal local installer.
if [[ ! -f $repo_root/.config/nvim/init.lua ]]; then
    if $dry_run; then
        printf 'Planned: clone/update ~/kairo and run the selected installer options.\n'
        printf 'For a detailed zero-write preview, run --dry-run from an existing checkout.\n'
        exit 0
    fi
    kairo_checkout="$HOME/kairo"
    if ! $non_interactive && [[ -t 1 && ${CI:-false} != true && -r /dev/tty ]]; then
        command -v sudo >/dev/null 2>&1 || {
            printf 'sudo is required for interactive system setup.\n' >&2
            exit 1
        }
        printf 'Kairo needs administrator access for system packages and setup.\n'
        sudo -v </dev/tty
    fi
    if ! command -v git >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
            sudo pacman -S --needed git </dev/tty
        else
            printf 'Git is required to clone Kairo.\n' >&2
            exit 1
        fi
    fi
    if [[ -e $kairo_checkout ]]; then
        [[ -d $kairo_checkout/.git ]] || {
            printf '%s already exists and is not a Git checkout.\n' "$kairo_checkout" >&2
            exit 1
        }
        checkout_origin=$(git -C "$kairo_checkout" remote get-url origin 2>/dev/null || true)
        [[ $checkout_origin == https://github.com/nihitdev/kairo.git ||
           $checkout_origin == git@github.com:nihitdev/kairo.git ]] || {
            printf '%s is not a Kairo checkout; refusing to replace it.\n' "$kairo_checkout" >&2
            exit 1
        }
        [[ -z $(git -C "$kairo_checkout" status --porcelain) ]] || {
            printf '%s has local changes; commit or stash them before updating.\n' "$kairo_checkout" >&2
            exit 1
        }
        printf 'Updating %s...\n' "$kairo_checkout"
        git -C "$kairo_checkout" pull --ff-only origin main
    else
        printf 'Cloning Kairo -> %s...\n' "$kairo_checkout"
        git clone https://github.com/nihitdev/kairo.git "$kairo_checkout"
    fi
    printf 'Starting Kairo...\n'
    set +e
    if ! $non_interactive && [[ -t 1 && ${CI:-false} != true && ${#only[@]} -eq 0 && -r /dev/tty ]]; then
        (cd "$kairo_checkout" && bash ./install.sh "${original_args[@]}" </dev/tty)
    else
        (cd "$kairo_checkout" && bash ./install.sh "${original_args[@]}")
    fi
    remote_status=$?
    set -e
    exit "$remote_status"
fi

timestamp=$(date '+%Y%m%d-%H%M%S')
backup_root=''
backup_display="$HOME/.dotfiles-backup/<unique-run>"
config_root=${XDG_CONFIG_HOME:-"$HOME/.config"}
source_config_root="$repo_root/.config"
kairo_shell_data=${XDG_DATA_HOME:-"$HOME/.local/share"}
kairo_shell_target="$kairo_shell_data/kairo"
kairo_shell_bin=${KAIRO_BIN_DIR:-"$HOME/.local/bin"}
kairo_shell_state="${XDG_STATE_HOME:-$HOME/.local/state}/kairo"

command -v realpath >/dev/null 2>&1 || {
    printf 'realpath is required for safe destination validation.\n' >&2
    exit 1
}

ensure_backup_root() {
    if [[ -n $backup_root ]]; then
        return
    fi
    mkdir -p -- "$HOME/.dotfiles-backup"
    chmod 700 "$HOME/.dotfiles-backup"
    backup_root=$(mktemp -d -- "$HOME/.dotfiles-backup/$timestamp.XXXXXX")
    chmod 700 "$backup_root"
}

if [[ $HOME != /* || $HOME == / || $HOME == *'/../'* || $HOME == */.. ]]; then
    printf 'HOME must be an absolute, specific path without parent traversal: %s\n' "$HOME" >&2
    exit 1
fi
if [[ $config_root != /* || $config_root == *'/../'* || $config_root == */.. ]]; then
    printf 'XDG_CONFIG_HOME must be an absolute path without parent traversal: %s\n' "$config_root" >&2
    exit 1
fi

home_resolved=$(realpath -m -- "$HOME")
config_root_resolved=$(realpath -m -- "$config_root")
case "$config_root_resolved" in
    "$home_resolved"/*) ;;
    *)
        printf 'XDG_CONFIG_HOME must resolve inside HOME: %s\n' "$config_root" >&2
        exit 1
        ;;
esac

rollback_transaction() {
    local index destination previous had_previous

    $transaction_active || return 0
    trap - ERR INT TERM
    printf 'Installation failed; rolling back completed changes...\n' >&2
    for ((index=${#transaction_destinations[@]} - 1; index >= 0; index--)); do
        destination=${transaction_destinations[index]}
        previous=${transaction_previous[index]}
        had_previous=${transaction_had_previous[index]}
        if [[ -e $destination || -L $destination ]]; then
            rm -rf -- "$destination"
        fi
        if [[ $had_previous == true && ( -e $previous || -L $previous ) ]]; then
            mv -- "$previous" "$destination"
        fi
    done
    transaction_active=false
}

rollback_system_changes() {
    if [[ -n $sddm_receipt && -s $sddm_receipt ]]; then
        printf 'Restoring SDDM after a later installation failure...\n' >&2
        local sddm_backup
        IFS= read -r sddm_backup < "$sddm_receipt"
        if ! bash "$repo_root/.local/share/sddm/themes/archnemesis/rollback.sh" "$sddm_backup"; then
            printf 'SDDM recovery failed; restore manually from %s\n' "$sddm_backup" >&2
        fi
        sddm_receipt=''
    fi
    if $chaotic_config_changed && [[ -n $chaotic_config_backup && -f $chaotic_config_backup ]]; then
        printf 'Restoring /etc/pacman.conf after failure...\n' >&2
        if ((EUID == 0)); then
            cp -- "$chaotic_config_backup" /etc/pacman.conf
        elif command -v sudo >/dev/null 2>&1; then
            sudo cp -- "$chaotic_config_backup" /etc/pacman.conf
        fi
        chaotic_config_changed=false
    fi
}

commit_transaction() {
    local previous
    transaction_active=false
    for previous in "${transaction_previous[@]}"; do
        if [[ -n $previous && ( -e $previous || -L $previous ) ]]; then
            if ! rm -rf -- "$previous"; then
                printf 'Warning: could not remove transaction artifact: %s\n' "$previous" >&2
            fi
        fi
    done
}

handle_failure() {
    local status=$? failed_command=${BASH_COMMAND:-unknown} failed_line=${BASH_LINENO[0]:-unknown}
    trap - ERR INT TERM
    printf 'Installation failed at line %s (exit %s): %s\n' "$failed_line" "$status" "$failed_command" >&2
    rollback_transaction
    rollback_system_changes
    if $interactive && declare -F ui_failure >/dev/null; then
        ui_failure "Line $failed_line: $failed_command (exit $status)."
        IFS= read -rsn1 _ || true
        printf '\n'
    fi
    exit "$status"
}

handle_interrupt() {
    trap - ERR INT TERM
    rollback_transaction
    rollback_system_changes
    exit 130
}

trap handle_failure ERR
trap handle_interrupt INT TERM

is_selected() {
    local component=$1
    local selected

    if [[ $component == wallpapers ]]; then
        $install_wallpapers
        return
    fi

    if [[ $component == kitty ]] && is_selected kitty-smooth; then return 0; fi

    # Hyprland includes Waybar unless the alternative desktop shell is selected.
    if [[ $component == waybar ]] && ! is_selected kairo-shell && is_selected hypr; then
        return 0
    fi
    if ((${#only[@]} == 0)); then
        [[ ${module_default[$component]:-false} == true ]]
        return
    fi
    for selected in "${only[@]}"; do
        [[ $selected == all || $selected == "$component" ]] && return 0
    done
    return 1
}

module_label() {
    local component=$1 index
    for ((index=0; index<${#module_names[@]}; index++)); do
        if [[ ${module_names[index]} == "$component" ]]; then
            printf '%s' "${module_labels[index]}"
            return
        fi
    done
    printf '%s' "$component"
}

record_unique() {
    local -n target=$1
    local value=$2 existing
    for existing in "${target[@]}"; do
        [[ $existing == "$value" ]] && return
    done
    target+=("$value")
}

payload_is_current() {
    local source=$1 destination=$2
    [[ -e $destination || -L $destination ]] || return 1
    if [[ -L $source || -L $destination ]]; then
        [[ -L $source && -L $destination ]] || return 1
        [[ $(readlink -- "$source") == "$(readlink -- "$destination")" ]]
    elif [[ -f $source && -f $destination ]]; then
        cmp -s -- "$source" "$destination"
    elif [[ -d $source && -d $destination ]]; then
        diff -qr -- "$source" "$destination" >/dev/null 2>&1
    else
        return 1
    fi
}

describe() {
    if $interactive && declare -F ui_status >/dev/null; then
        case "$*" in
            *'already current'*) ui_status ok "$*" ;;
            'Back up '* | 'Replace '* | 'Regenerate '*) ui_status changed "$*" ;;
            'Install '* | 'Set default shell'*) ui_status ok "$*" ;;
            'All selected packages'*) ui_status ok "$*" ;;
            *) printf '  %s\n' "$*" ;;
        esac
        return
    fi
    if $dry_run; then
        printf '[dry-run] %s\n' "$*"
    else
        printf '%s\n' "$*"
    fi
}

record_installed() {
    local component=$1
    local existing
    for existing in "${installed[@]}"; do
        [[ $existing == "$component" ]] && return
    done
    installed+=("$component")
}

record_current() {
    record_unique already_current "$1"
}

component_was_applied() {
    local component=$1 existing
    for existing in "${installed[@]}" "${already_current[@]}"; do
        [[ $existing == "$component" ]] && return 0
    done
    return 1
}

package_is_installed() {
    local package=$1 command_name=${2:-}
    if command -v pacman >/dev/null 2>&1; then
        if ! $package_cache_loaded; then
            local installed_package
            while IFS= read -r installed_package; do
                [[ -n $installed_package ]] && installed_package_cache["$installed_package"]=true
            done < <(pacman -Qq 2>/dev/null || true)
            package_cache_loaded=true
        fi
        [[ ${installed_package_cache[$package]:-false} == true ]] && return 0
    fi
    [[ -n $command_name ]] && command -v "$command_name" >/dev/null 2>&1
}

collect_missing_packages() {
    local component package command_name profile
    missing_official_packages=()
    missing_aur_packages=()
    for component in "${module_names[@]}"; do
        is_selected "$component" || continue
        if [[ $component == waybar ]] && is_selected kairo-shell; then continue; fi
        command_name=${module_command[$component]:-}
        if [[ -n ${module_package[$component]:-} ]]; then
            package=${module_package[$component]}
            package_is_installed "$package" "$command_name" || record_unique missing_official_packages "$package"
        elif [[ -n ${module_aur_package[$component]:-} ]]; then
            package=${module_aur_package[$component]}
            package_is_installed "$package" "$command_name" || record_unique missing_aur_packages "$package"
        fi
    done
    if [[ $default_shell != keep ]]; then
        package_is_installed "$default_shell" "${module_command[$default_shell]}" ||
            record_unique missing_official_packages "$default_shell"
    fi
    if is_selected kitty-smooth; then
        for package in "${kitty_smooth_packages[@]}"; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if is_selected plymouth; then
        package_is_installed python || record_unique missing_official_packages python
    fi
    if is_selected sddm; then
        for package in qt6-declarative ttf-iosevka-nerd python; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if is_selected hypr; then
        package_is_installed mpvpaper || record_unique missing_aur_packages mpvpaper
        for package in "${hypr_packages[@]}"; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if is_selected waybar && ! is_selected kairo-shell; then
        for package in "${waybar_packages[@]}"; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if is_selected zsh; then
        for package in zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search fzf; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
        package_is_installed git git || record_unique missing_official_packages git
    fi
    if is_selected bash || is_selected fish || is_selected nushell; then
        package_is_installed zoxide zoxide || record_unique missing_official_packages zoxide
    fi
    if is_selected fish; then
        package_is_installed fisher || record_unique missing_official_packages fisher
    fi
    if is_selected prism; then
        package_is_installed python python3 || record_unique missing_official_packages python
    fi
    if is_selected zsh || is_selected fish; then
        # Shared interactive tools, previews, editor defaults, and integrations.
        for package in git fzf fd eza bat neovim yazi lazygit btop starship zoxide mise direnv; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if is_selected kairo-shell; then
        for package in "${kairo_shell_packages[@]}"; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
        package_is_installed wl-gammarelay-rs || record_unique missing_aur_packages wl-gammarelay-rs
    fi
    if is_selected wezterm; then
        package_is_installed zsh zsh || record_unique missing_official_packages zsh
        package_is_installed ttf-jetbrains-mono-nerd || record_unique missing_official_packages ttf-jetbrains-mono-nerd
    fi
    if is_selected nvim; then
        package_is_installed git git || record_unique missing_official_packages git
        # Language extras need runtimes for tests/DAP and Mason's installers.
        # Mason owns LSPs/debug adapters and stylua/shfmt/goimports/gofumpt;
        # these formatter fallbacks are explicitly configured but not Mason-managed.
        for package in curl unzip tar gzip gcc make ripgrep fd nodejs npm go zig prettier ruff taplo-cli; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
        # rustaceanvim disables mason-lspconfig's rust_analyzer installation.
        # Arch's rust-analyzer pulls rust-src and a Rust provider (including rustfmt).
        package_is_installed rust-analyzer rust-analyzer || record_unique missing_official_packages rust-analyzer
    fi
    for profile in "${profiles[@]}"; do
        for package in ${profile_packages[$profile]}; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    done
    if $install_gpu_drivers; then
        for package in "${gpu_packages[@]}"; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
    fi
    if ((${#missing_aur_packages[@]})) && ! command -v "$aur_helper" >/dev/null 2>&1; then
        package_is_installed base-devel || record_unique missing_official_packages base-devel
        package_is_installed git git || record_unique missing_official_packages git
    fi
}

detect_gpu_drivers() {
    local gpu_lines kernel_package module_dir
    gpu_packages=()
    command -v lspci >/dev/null 2>&1 || {
        gpu_description='lspci unavailable (install pciutils for detection)'
        return 0
    }
    gpu_lines=$(lspci -nn 2>/dev/null | grep -Ei 'VGA|3D|Display' || true)
    [[ -n $gpu_lines ]] || return 0
    gpu_description=$(printf '%s' "$gpu_lines" | sed -E 's/^[^:]+: //; s/ \[[0-9a-fA-F:]+\].*$//' | paste -sd ' + ' -)
    if grep -Eqi 'AMD|ATI|Radeon' <<<"$gpu_lines"; then
        record_unique gpu_packages mesa
        record_unique gpu_packages vulkan-radeon
    fi
    if grep -Eqi 'Intel' <<<"$gpu_lines"; then
        record_unique gpu_packages mesa
        record_unique gpu_packages vulkan-intel
        record_unique gpu_packages intel-media-driver
    fi
    if grep -Eqi 'NVIDIA' <<<"$gpu_lines"; then
        if grep -Eqi 'RTX|GTX 16|Blackwell|Ada|Ampere|Turing' <<<"$gpu_lines"; then
            record_unique gpu_packages nvidia-open-dkms
            record_unique gpu_packages nvidia-utils
            record_unique gpu_packages libva-nvidia-driver
            for module_dir in /usr/lib/modules/*; do
                [[ -r $module_dir/pkgbase ]] || continue
                kernel_package=$(<"$module_dir/pkgbase")
                package_is_installed "$kernel_package-headers" || record_unique gpu_packages "$kernel_package-headers"
            done
        else
            warnings+=('NVIDIA GPU generation could not be classified safely; choose the correct legacy/current driver manually')
        fi
    fi
}

acquire_privileges() {
    local needs_root=false
    ((${#missing_official_packages[@]})) && $install_packages && needs_root=true
    $enable_chaotic_aur && needs_root=true
    is_selected sddm && needs_root=true
    is_selected plymouth && needs_root=true
    $needs_root || return 0
    if ((EUID == 0)); then
        warnings+=('Kairo is running as root; AUR builds remain disabled for safety')
        return 0
    fi
    command -v sudo >/dev/null 2>&1 || { printf 'sudo is required for the selected system changes.\n' >&2; return 1; }
    if $dry_run; then
        describe 'Validate sudo credentials before installation'
        return 0
    fi
    if $interactive; then
        ui_heading
        ui_section 'Authorization'
        printf '\n  Kairo needs administrator access for the reviewed system changes.\n'
        printf '  Your credentials are handled directly by sudo and are never stored.\n\n'
    fi
    sudo -v
    describe 'Administrator credentials validated'
}

bootstrap_aur_helper() {
    command -v "$aur_helper" >/dev/null 2>&1 && return 0
    ((EUID != 0)) || { printf 'Refusing to build an AUR helper as root.\n' >&2; return 1; }
    command -v git >/dev/null 2>&1 || { printf 'git is required to bootstrap %s.\n' "$aur_helper" >&2; return 1; }
    command -v makepkg >/dev/null 2>&1 || { printf 'base-devel is required to bootstrap %s.\n' "$aur_helper" >&2; return 1; }
    ensure_external_root
    local package_base=$aur_helper
    [[ $aur_helper == paru ]] && package_base=paru-bin
    describe "Bootstrap $aur_helper from the reviewed AUR PKGBUILD"
    git clone --depth=1 "https://aur.archlinux.org/$package_base.git" "$external_root/$package_base"
    (
        cd -- "$external_root/$package_base"
        makepkg -si --needed
    )
    command -v "$aur_helper" >/dev/null 2>&1
}

enable_chaotic_repository() {
    $enable_chaotic_aur || return 0
    if grep -Eq '^\[chaotic-aur\][[:space:]]*$' /etc/pacman.conf 2>/dev/null; then
        describe 'Chaotic-AUR is already enabled'
        return
    fi
    command -v pacman >/dev/null 2>&1 || { printf 'Chaotic-AUR requires Arch Linux and pacman.\n' >&2; return 1; }
    if $dry_run; then
        describe 'Trust and locally sign Chaotic-AUR key 3056513887B78AEB'
        describe 'Install chaotic-keyring and chaotic-mirrorlist from cdn-mirror.chaotic.cx'
        describe 'Append [chaotic-aur] to /etc/pacman.conf and synchronize package databases'
        return
    fi
    ensure_external_root
    if ! $no_backup; then
        ensure_backup_root
        mkdir -p -m 700 -- "$backup_root/system"
        chaotic_config_backup="$backup_root/system/pacman.conf"
    else
        chaotic_config_backup="$external_root/pacman.conf.before-chaotic"
    fi
    cp -- /etc/pacman.conf "$chaotic_config_backup"
    chmod 600 "$chaotic_config_backup"
    cp -- /etc/pacman.conf "$external_root/pacman.conf.new"
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >>"$external_root/pacman.conf.new"
    local -a elevate=()
    if ((EUID != 0)); then
        command -v sudo >/dev/null 2>&1 || { printf 'sudo is required to enable Chaotic-AUR.\n' >&2; return 1; }
        elevate=(sudo)
    fi
    "${elevate[@]}" pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    "${elevate[@]}" pacman-key --lsign-key 3056513887B78AEB
    "${elevate[@]}" pacman -U --needed \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    "${elevate[@]}" install -m 644 "$external_root/pacman.conf.new" /etc/pacman.conf
    chaotic_config_changed=true
    "${elevate[@]}" pacman -Sy
    describe 'Enabled Chaotic-AUR'
}

install_missing_packages() {
    if ((${#missing_official_packages[@]} == 0 && ${#missing_aur_packages[@]} == 0)); then
        describe 'All selected packages are already available'
        return
    fi
    if ! $install_packages; then
        if ((${#missing_official_packages[@]})); then
            warnings+=("Missing official packages: ${missing_official_packages[*]}")
        fi
        if ((${#missing_aur_packages[@]})); then
            warnings+=("Missing AUR packages: ${missing_aur_packages[*]}")
        fi
        return 0
    fi
    if ! command -v pacman >/dev/null 2>&1; then
        printf '%s\n' '--install-packages requires Arch Linux with pacman.' >&2
        return 1
    fi
    if $dry_run; then
        ((${#missing_official_packages[@]})) && describe "Run sudo pacman -S --needed ${missing_official_packages[*]}"
        ((${#missing_aur_packages[@]})) && describe "Run $aur_helper -S --needed ${missing_aur_packages[*]}"
        return 0
    fi
    if ((${#missing_official_packages[@]})); then
        if ((EUID == 0)); then
            pacman -S --needed "${missing_official_packages[@]}"
        else
            command -v sudo >/dev/null 2>&1 || { printf 'sudo is required to install official packages.\n' >&2; return 1; }
            sudo pacman -S --needed "${missing_official_packages[@]}"
        fi
    fi
    if ((${#missing_aur_packages[@]})); then
        ((EUID != 0)) || { printf 'Refusing to run an AUR helper as root.\n' >&2; return 1; }
        command -v "$aur_helper" >/dev/null 2>&1 || bootstrap_aur_helper
        "$aur_helper" -S --needed "${missing_aur_packages[@]}"
    fi
    installed_package_cache=()
    package_cache_loaded=false
}

validate_kairo_shell_destinations() {
    is_selected kairo-shell || return 0
    local destination name
    for destination in "$kairo_shell_target" "$kairo_shell_bin/kairo" "$kairo_shell_bin/kairod" \
        "$config_root/kairo/settings.json" "$kairo_shell_state/version" \
        "$kairo_shell_data/applications/kairo.desktop" "$kairo_shell_data/icons/hicolor/scalable/apps/kairo.svg"; do
        assert_safe_destination "$destination"
    done
    if [[ -e $kairo_shell_target && ! -f $kairo_shell_target/.kairo-install &&
          ! -f $kairo_shell_target/bin/kairod ]]; then
        printf 'Refusing to replace unmanaged Kairo Shell directory: %s\n' "$kairo_shell_target" >&2
        return 1
    fi
    for name in kairo kairod; do
        destination="$kairo_shell_bin/$name"
        if [[ -e $destination || -L $destination ]]; then
            if [[ ! -L $destination || $(readlink -- "$destination") != "$kairo_shell_target/bin/$name" ]]; then
                printf 'Kairo Shell launcher conflicts with an existing file: %s\n' "$destination" >&2
                return 1
            fi
        fi
    done
}

install_kairo_shell() {
    is_selected kairo-shell || return 0
    local checkout payload name
    if $dry_run; then
        describe "Fetch Kairo Shell $kairo_shell_version ($kairo_shell_commit)"
        describe "Install kairo-shell -> $kairo_shell_target"
        describe "Install Kairo Shell launchers -> $kairo_shell_bin"
        describe "Seed Kairo Shell settings -> $config_root/kairo/settings.json (preserve existing)"
        describe "Install Kairo Shell version state -> $kairo_shell_state/version"
        describe "Install Kairo Shell desktop entry and icon -> $kairo_shell_data"
        record_installed kairo-shell
        return 0
    fi

    ensure_external_root
    checkout="$external_root/kairo-shell-checkout"
    payload="$external_root/kairo-shell-payload"
    describe "Fetch Kairo Shell $kairo_shell_version"
    git clone --depth 1 --branch "$kairo_shell_version" "$kairo_shell_repo" "$checkout"
    if [[ $(git -C "$checkout" rev-parse HEAD) != "$kairo_shell_commit" ]]; then
        printf 'Kairo Shell release does not match the reviewed commit.\n' >&2
        return 1
    fi

    mkdir -p -- "$payload"
    cp -a -- "$checkout/bin" "$checkout/src" "$checkout/config" "$checkout/compositors" "$payload/"
    cp -- "$checkout/version.txt" "$payload/src/version.txt"
    cp -- "$checkout/LICENSE.md" "$checkout/UPSTREAM.md" "$checkout/CHANGELOG.md" "$checkout/README.md" "$payload/src/"
    cp -- "$checkout/install/uninstall.sh" "$payload/uninstall.sh"
    chmod +x "$payload/bin/kairo" "$payload/bin/kairod" "$payload/uninstall.sh"
    find "$payload/src" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
    printf 'Kairo managed installation\n' > "$payload/.kairo-install"
    install_item kairo-shell "$payload" "$kairo_shell_target"
    for name in kairo kairod; do
        ln -s -- "$kairo_shell_target/bin/$name" "$external_root/$name"
        install_item kairo-shell "$external_root/$name" "$kairo_shell_bin/$name"
    done
    install_seed_item kairo-shell "$checkout/config/kairo/settings.json" "$config_root/kairo/settings.json"
    printf 'KAIRO_VERSION="%s"\nKAIRO_COMMIT="%s"\nCOMPOSITOR="hyprland"\n' \
        "${kairo_shell_version#v}" "${kairo_shell_commit:0:7}" > "$external_root/kairo-version"
    install_item kairo-shell "$external_root/kairo-version" "$kairo_shell_state/version"
    install_item kairo-shell "$checkout/src/assets/applications/kairo.desktop" "$kairo_shell_data/applications/kairo.desktop"
    install_item kairo-shell "$checkout/src/assets/kairo-logo.svg" "$kairo_shell_data/icons/hicolor/scalable/apps/kairo.svg"
}

preflight_desktop() {
    local module file
    preflight_kitty_smooth
    if is_selected prism; then
        for file in prism.py README.md init.sh current theme.sh fzf.txt nu-colors.json; do
            [[ -r $source_config_root/prism/$file ]] || {
                printf 'Missing Prism payload: %s\n' "$source_config_root/prism/$file" >&2; return 1;
            }
        done
        [[ -x $source_config_root/prism/prism.py && -x $repo_root/.local/bin/prism ]] || {
            printf 'Prism entrypoints must be executable.\n' >&2; return 1;
        }
        assert_safe_destination "$config_root/prism"
        assert_safe_destination "$HOME/.local/bin/prism"
    fi
    if is_selected plymouth; then
        bash "$repo_root/.local/share/plymouth/install.sh" --dry-run >/dev/null
    fi
    if is_selected sddm; then
        for file in Main.qml metadata.desktop theme.conf background.png preview.png install.sh rollback.sh; do
            [[ -r "$repo_root/.local/share/sddm/themes/archnemesis/$file" ]] || {
                printf 'Missing SDDM payload: %s\n' "$file" >&2; return 1;
            }
        done
        bash -n "$repo_root/.local/share/sddm/themes/archnemesis/install.sh"
        bash -n "$repo_root/.local/share/sddm/themes/archnemesis/rollback.sh"
    fi
    if is_selected hypr || $install_wallpapers; then
        local wallpaper_source="$repo_root/.local/share/wallpapers/archnemesis"
        [[ -r $wallpaper_source/snow-pine-forest.png ]] || {
            printf 'Missing default wallpaper: snow-pine-forest.png\n' >&2; return 1;
        }
        assert_safe_destination "$HOME/Pictures/Wallpapers"
        while IFS= read -r -d '' file; do
            assert_safe_destination "$HOME/Pictures/Wallpapers/${file#"$wallpaper_source"/}"
        done < <(find "$wallpaper_source" -maxdepth 1 -type f -print0)
    fi
    for module in hypr waybar; do
        is_selected "$module" || continue
        [[ $module != waybar ]] || ! is_selected kairo-shell || continue
        [[ -d $source_config_root/$module ]] || {
            printf 'Missing desktop payload: %s\n' "$module" >&2; return 1;
        }
        assert_safe_destination "$config_root/$module"
        while IFS= read -r -d '' file; do
            case "$file" in
                *.sh) bash -n "$file" ;;
                *.lua) if command -v luac >/dev/null 2>&1; then luac -p "$file"; fi ;;
            esac
        done < <(find "$source_config_root/$module" -type f \( -name '*.sh' -o -name '*.lua' \) -print0)
    done
    if is_selected hypr; then
        for file in config.toml templates/hyprland-colors.lua templates/waybar-colors.css \
            templates/kitty-colors.conf templates/rofi-colors.rasi templates/hyprlock.conf.in \
            templates/qs-theme.qml; do
            [[ -r $source_config_root/matugen/$file ]] || {
                printf 'Missing Matugen palette payload: %s\n' "$file" >&2; return 1;
            }
        done
        assert_safe_destination "$config_root/matugen"
        [[ -x $repo_root/.local/bin/battery-guardian ]] || {
            printf 'Missing battery guardian helper.\n' >&2; return 1;
        }
        bash -n "$repo_root/.local/bin/battery-guardian"
        assert_safe_destination "$HOME/.local/bin/battery-guardian"
        for module in hyprlock rofi quickshell/wallpaper-picker awww; do
            [[ -d $source_config_root/$module ]] || {
                printf 'Missing desktop payload: %s\n' "$module" >&2; return 1;
            }
            assert_safe_destination "$config_root/$module"
        done
        if ! is_selected kairo-shell; then
            [[ -d $source_config_root/quickshell/hyprland-notifications ]] || {
                printf 'Missing Hyprland notification shell payload.\n' >&2; return 1;
            }
            assert_safe_destination "$config_root/quickshell/hyprland-notifications"
        fi
        [[ -r $source_config_root/awww/archnemesis.toml ]] || {
            printf 'Missing awww transition config: %s\n' "$source_config_root/awww/archnemesis.toml" >&2; return 1;
        }
        for file in hyprland.lua hyprpaper.conf config/windows.lua config/colors.lua shortcuts.txt \
            scripts/apply-wallpaper-theme.sh scripts/keybinds.sh scripts/reload.sh scripts/scratchpad.sh \
            scripts/toggle-layout.sh; do
            [[ -r $source_config_root/hypr/$file ]] || {
                printf 'Missing Hyprland payload: %s\n' "$file" >&2; return 1;
            }
            if [[ $file == scripts/*.sh && ! -x $source_config_root/hypr/$file ]]; then
                printf 'Hyprland helper is not executable: %s\n' "$file" >&2; return 1
            fi
        done
    fi
    if is_selected waybar && ! is_selected kairo-shell; then
        [[ -f $source_config_root/waybar/config.jsonc &&
           -f $source_config_root/waybar/style.css &&
           -f $source_config_root/waybar/colors.css &&
           -f $source_config_root/waybar/scripts/fonts/Waycat.ttf &&
           -f $source_config_root/waybar/scripts/fonts/Skulltype.ttf ]] || return 1
        assert_safe_destination "$kairo_shell_data/fonts/archnemesis"
        if command -v python3 >/dev/null 2>&1; then
            python3 -m json.tool "$source_config_root/waybar/config.jsonc" >/dev/null
        fi
    fi
}

install_curated_wallpapers() {
    local component=wallpapers
    if is_selected hypr; then
        component=hypr
    elif ! $install_wallpapers; then
        return 0
    fi
    local source="$repo_root/.local/share/wallpapers/archnemesis" file destination
    # Seed individual files: keep personal images and participate in rollback.
    while IFS= read -r -d '' file; do
        destination="$HOME/Pictures/Wallpapers/${file#"$source"/}"
        install_seed_item "$component" "$file" "$destination"
    done < <(find "$source" -maxdepth 1 -type f -print0 | sort -z)
}

install_hypr_desktop() {
    is_selected hypr || return 0
    local hypr_source="$source_config_root/hypr" temp_hypr command wallpaper=''
    local saved="$HOME/.cache/current-wallpaper"
    # Preserve the recipient's choice; never distribute the author's absolute symlink.
    if [[ -f $config_root/hypr/current-wallpaper ]]; then
        wallpaper=$(realpath -- "$config_root/hypr/current-wallpaper")
    elif [[ -r $saved ]]; then
        IFS= read -r wallpaper < "$saved" || true
        [[ -f $wallpaper ]] || wallpaper=''
    fi
    if [[ -z $wallpaper ]]; then
        wallpaper="$HOME/Pictures/Wallpapers/snow-pine-forest.png"
    fi
    if [[ ! -f $wallpaper ]] && ! $dry_run; then
        wallpaper=''
    fi
    if [[ -z $wallpaper && -f /usr/share/hypr/wall0.png ]]; then
        wallpaper=/usr/share/hypr/wall0.png
    fi
    if [[ -n $wallpaper ]]; then
        describe "Preserve/seed wallpaper -> $wallpaper"
    else
        warnings+=('No wallpaper found: add images to ~/Pictures/Wallpapers and press Super+Alt+Space')
    fi
    if is_selected kairo-shell; then
        describe "Configure Hyprland startup -> $kairo_shell_bin/kairod start"
        describe 'Skip Waybar deployment because Kairo Shell is selected'
    fi
    install_item hypr "$source_config_root/quickshell/wallpaper-picker" "$config_root/quickshell/wallpaper-picker"
    if ! is_selected kairo-shell; then
        install_item hypr "$source_config_root/quickshell/hyprland-notifications" "$config_root/quickshell/hyprland-notifications"
    fi
    install_item hypr "$source_config_root/awww" "$config_root/awww"
    install_item hypr "$source_config_root/hyprlock" "$config_root/hyprlock"
    install_item hypr "$source_config_root/matugen" "$config_root/matugen"
    # Required by the existing keybinds; preserve a user's custom Rofi setup.
    if ! is_selected rofi; then
        install_seed_item hypr "$source_config_root/rofi" "$config_root/rofi"
    fi
    install_item hypr "$repo_root/.local/bin/battery-guardian" "$HOME/.local/bin/battery-guardian"
    if $dry_run; then
        install_item hypr "$hypr_source" "$config_root/hypr"
        return 0
    fi
    ensure_external_root
    temp_hypr="$external_root/hypr"
    cp -a -- "$hypr_source" "$temp_hypr"
    if is_selected kairo-shell; then
        sed -i '\|hyprland-notifications|d' "$temp_hypr/config/autostart.lua"
    fi
    if [[ -n $wallpaper ]]; then
        if [[ $wallpaper == "$config_root/hypr/"* ]]; then
            cp -L -- "$wallpaper" "$temp_hypr/current-wallpaper"
        else
            ln -sfn -- "$wallpaper" "$temp_hypr/current-wallpaper"
        fi
    fi
    # Keep saved live-wallpaper state across replacement of the Hyprland tree.
    if [[ -f $config_root/hypr/current-live-wallpaper ]]; then
        local live_wallpaper
        live_wallpaper=$(realpath -- "$config_root/hypr/current-live-wallpaper")
        if [[ $live_wallpaper == "$config_root/hypr/"* ]]; then
            cp -L -- "$live_wallpaper" "$temp_hypr/current-live-wallpaper"
        else
            ln -sfn -- "$live_wallpaper" "$temp_hypr/current-live-wallpaper"
        fi
    fi
    if is_selected kairo-shell; then
        # Shell quote the installed launcher, then encode the command for Lua.
        command="'${kairo_shell_bin//\'/\'\\\'\'}/kairod' start"
        command=${command//\\/\\\\}
        command=${command//\"/\\\"}
        printf 'return "%s"\n' "$command" > "$temp_hypr/config/bar.lua"
        # Kairo Shell owns its own palette and startup flow.
        sed -i '/Generate the shared wallpaper palette once per login/d; /apply-wallpaper-theme.sh/d' "$temp_hypr/config/autostart.lua"
        # The current live config starts Waybar directly; replace only that entry.
        sed -i '/^[[:space:]]*"waybar",[[:space:]]*$/d' "$temp_hypr/config/autostart.lua"
        sed -i '/    -- Session daemons\./i\    hl.exec_cmd(require("config.bar"))\n' "$temp_hypr/config/autostart.lua"
    fi
    install_item hypr "$temp_hypr" "$config_root/hypr"
}

install_kitty() {
    is_selected kitty || return 0
    local payload="$source_config_root/kitty"
    if ! $dry_run; then
        ensure_external_root
        payload="$external_root/kitty"
        cp -a -- "$source_config_root/kitty" "$payload"
        if [[ -e $config_root/kitty/user.conf || -L $config_root/kitty/user.conf ]]; then
            if is_selected kitty-smooth; then
                rm -f -- "$payload/user.conf"
                cp -L -- "$config_root/kitty/user.conf" "$payload/user.conf"
                python3 "$repo_root/.config/scripts/kitty-smooth-config.py" "$payload/user.conf"
            else
                cp -a -- "$config_root/kitty/user.conf" "$payload/user.conf"
            fi
        fi
    fi
    install_item kitty "$payload" "$config_root/kitty"
}

install_waybar() {
    is_selected waybar || return 0
    is_selected kairo-shell && return 0
    install_item waybar "$source_config_root/waybar" "$config_root/waybar"
    install_item waybar "$source_config_root/waybar/scripts/fonts" "$kairo_shell_data/fonts/archnemesis"
    if is_selected hypr && command -v systemctl >/dev/null 2>&1; then
        if $dry_run; then
            describe 'Enable Waybar in graphical-session.target (systemctl --user enable waybar.service)'
        elif systemctl --user enable waybar.service >/dev/null 2>&1; then
            if systemctl --user is-active --quiet graphical-session.target &&
                ! pgrep -u "$(id -u)" -x waybar >/dev/null 2>&1; then
                systemctl --user start waybar.service ||
                    warnings+=('Waybar service is enabled but could not be started in this session')
            fi
        else
            warnings+=('Could not enable waybar.service; enable it with systemctl --user enable waybar.service')
        fi
    fi
    if ! is_selected hypr; then
        warnings+=('Waybar actions expect the matching Hyprland scripts and custom Rofi setup; use --only hypr for the complete desktop')
    fi
}

assert_safe_destination() {
    local destination=$1
    local resolved parent ancestor

    case "$destination" in
        '' | / | "$HOME" | "$config_root" | *'/../'* | */..)
            printf 'Refusing unsafe destination: %s\n' "$destination" >&2
            return 1
            ;;
        /*) ;;
        *)
            printf 'Destination must be absolute: %s\n' "$destination" >&2
            return 1
            ;;
    esac

    resolved=$(realpath -m -- "$destination")
    case "$resolved" in
        "$home_resolved"/*) ;;
        *)
            printf 'Destination escapes HOME: %s -> %s\n' "$destination" "$resolved" >&2
            return 1
            ;;
    esac

    # Resolve every existing parent now. This rejects symlink escapes before a
    # staging directory or destructive operation can touch the target.
    parent=$(dirname -- "$destination")
    ancestor=$parent
    while [[ ! -e $ancestor && $ancestor != / ]]; do
        ancestor=$(dirname -- "$ancestor")
    done
    ancestor=$(realpath -- "$ancestor")
    case "$ancestor" in
        "$home_resolved" | "$home_resolved"/*) ;;
        *)
            printf 'Destination parent escapes HOME: %s -> %s\n' "$parent" "$ancestor" >&2
            return 1
            ;;
    esac
}

install_item() {
    local component=$1
    local source=$2
    local destination=$3

    if ! is_selected "$component"; then
        return
    fi
    if [[ ! -e $source ]]; then
        printf 'Missing source for %s: %s\n' "$component" "$source" >&2
        skipped+=("$component")
        return 1
    fi

    assert_safe_destination "$destination"

    if payload_is_current "$source" "$destination"; then
        describe "$component already current -> $destination"
        record_current "$component"
        return
    fi

    assert_safe_destination "$destination"

    local parent stage_dir staged previous='' had_previous=false relative backup
    parent=$(dirname -- "$destination")

    if $dry_run; then
        if [[ -e $destination || -L $destination ]]; then
            if ! $no_backup; then
                relative=${destination#"$HOME"/}
                backup="$backup_display/$relative"
                describe "Back up $destination -> $backup"
            fi
            describe "Replace $destination transactionally"
        else
            describe "Install $component -> $destination"
        fi
        record_installed "$component"
        return
    fi

    mkdir -p -- "$parent"
    assert_safe_destination "$destination"
    stage_dir=$(mktemp -d -- "$parent/.dotfiles-stage.XXXXXX")
    transaction_stages+=("$stage_dir")
    staged="$stage_dir/payload"
    cp -a -- "$source" "$staged"

    if [[ -e $destination || -L $destination ]]; then
        if ! $no_backup; then
            ensure_backup_root
            relative=${destination#"$HOME"/}
            backup="$backup_root/$relative"
            describe "Back up $destination -> $backup"
            mkdir -p -m 700 -- "$(dirname -- "$backup")"
            cp -a -- "$destination" "$backup"
        fi
        previous="$parent/.dotfiles-previous.$(basename -- "$destination").$$.${#transaction_destinations[@]}"
        had_previous=true
    fi

    describe "Install $component -> $destination"
    transaction_destinations+=("$destination")
    transaction_previous+=("$previous")
    transaction_had_previous+=("$had_previous")
    transaction_active=true
    if $had_previous; then
        mv -- "$destination" "$previous"
    fi
    mv -- "$staged" "$destination"
    rmdir -- "$stage_dir"
    record_installed "$component"
}

install_include_line() {
    local component=$1 destination=$2 line=$3 temp_source
    is_selected "$component" || return 0
    if [[ -f $destination ]] && grep -Fqx -- "$line" "$destination"; then
        return
    fi
    if $dry_run; then
        assert_safe_destination "$destination"
        if [[ -e $destination || -L $destination ]]; then
            if ! $no_backup; then
                describe "Back up $destination -> $backup_display/${destination#"$HOME"/}"
            fi
            describe "Replace $destination transactionally"
        else
            describe "Install $component -> $destination"
        fi
        record_installed "$component"
        return
    fi
    temp_source=$(mktemp)
    if [[ -f $destination ]]; then
        cp -- "$destination" "$temp_source"
    fi
    printf '\n%s\n' "$line" >>"$temp_source"
    install_item "$component" "$temp_source" "$destination"
    rm -f -- "$temp_source"
}

install_seed_item() {
    local component=$1 source=$2 destination=$3
    is_selected "$component" || return 0
    if [[ -e $destination || -L $destination ]]; then
        return 0
    fi
    install_item "$component" "$source" "$destination"
}

install_git_include() {
    local managed_path=$1 temp_source
    is_selected git || return 0
    if [[ -f $HOME/.gitconfig ]]; then
        if command -v git >/dev/null 2>&1 &&
            git config --file "$HOME/.gitconfig" --get-all include.path 2>/dev/null |
                grep -Fqx -- "$managed_path"; then
            return
        fi
        if grep -Fqx -- "    path = $managed_path" "$HOME/.gitconfig"; then
            return
        fi
    fi
    if $dry_run; then
        assert_safe_destination "$HOME/.gitconfig"
        if [[ -e $HOME/.gitconfig || -L $HOME/.gitconfig ]]; then
            if ! $no_backup; then
                describe "Back up $HOME/.gitconfig -> $backup_display/.gitconfig"
            fi
            describe "Replace $HOME/.gitconfig transactionally"
        else
            describe "Install git -> $HOME/.gitconfig"
        fi
        record_installed git
        return
    fi
    temp_source=$(mktemp)
    if [[ -f $HOME/.gitconfig ]]; then
        cp -- "$HOME/.gitconfig" "$temp_source"
    fi
    printf '\n[include]\n    path = %s\n' "$managed_path" >>"$temp_source"
    install_item git "$temp_source" "$HOME/.gitconfig"
    rm -f -- "$temp_source"
}

ensure_external_root() {
    if [[ -z $external_root ]]; then
        external_root=$(mktemp -d)
    fi
}

install_zsh_integrations() {
    is_selected zsh || return 0
    local zsh_root="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
    if [[ -r $zsh_root/oh-my-zsh/oh-my-zsh.sh ]]; then
        return
    fi
    if ! $install_packages; then
        warnings+=('Oh My Zsh is missing; rerun with --install-packages to install it')
        return
    fi
    if $dry_run; then
        describe "Clone Oh My Zsh -> $zsh_root/oh-my-zsh"
        return
    fi
    command -v git >/dev/null 2>&1 || { printf 'git is required to install Oh My Zsh.\n' >&2; return 1; }
    ensure_external_root
    if $interactive && declare -F ui_run_spinner >/dev/null; then
        ui_run_spinner 'Installing Oh My Zsh' \
            git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$external_root/oh-my-zsh"
    else
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$external_root/oh-my-zsh"
    fi
    install_item zsh "$external_root/oh-my-zsh" "$zsh_root/oh-my-zsh"
}

install_zsh_plugins() {
    is_selected zsh || return 0
    # These paths match the live modular plugin loader. Preserve existing installs.
    local root="$HOME/.local/share/zsh/plugins" index target checkout
    local -a names=(fzf-tab zsh-autopair zsh-you-should-use forgit)
    local -a repos=(Aloxaf/fzf-tab hlissner/zsh-autopair MichaelAquilina/zsh-you-should-use wfxr/forgit)
    local -a files=(fzf-tab.plugin.zsh autopair.zsh you-should-use.plugin.zsh forgit.plugin.zsh)
    # Reproduce the plugin revisions used by the working live configuration.
    local -a commits=(
        24105b15714bfec37989ed5c5b6e60f572253019
        449a7c3d095bc8f3d78cf37b9549f8bb4c383f3d
        5f3d129864ee4505043d88c3486224f1d75b692e
        3cd8dd081f988046dd2148e5002fedd08da514e3
    )
    for index in "${!names[@]}"; do
        target="$root/${names[index]}"
        [[ ! -r $target/${files[index]} && ! -r /usr/share/zsh/plugins/${names[index]}/${files[index]} ]] || continue
        assert_safe_destination "$target"
        if ! $install_packages; then
            warnings+=("${names[index]} is missing; rerun with --install-packages to install it")
            continue
        fi
        if $dry_run; then
            describe "Install Zsh plugin ${names[index]} (${commits[index]}) -> $target"
            continue
        fi
        ensure_external_root
        checkout="$external_root/${names[index]}"
        git clone --filter=blob:none --no-checkout "https://github.com/${repos[index]}.git" "$checkout"
        # Reset only the new staging checkout; retain its tracking branch for rice-update.
        git -C "$checkout" reset --hard "${commits[index]}"
        [[ -r $checkout/${files[index]} ]] || return 1
        install_item zsh "$checkout" "$target"
    done
}

install_lazyvim_plugins() {
    is_selected nvim || return 0
    if ! $install_packages; then
        warnings+=('LazyVim plugins were not synced; rerun with --install-packages to download them')
        return 0
    fi
    if $dry_run; then
        describe 'Bootstrap lazy.nvim and sync LazyVim plugins from lazy-lock.json'
        return 0
    fi
    command -v nvim >/dev/null 2>&1 || {
        warnings+=('Neovim is unavailable; skipped LazyVim plugin installation')
        return 0
    }
    if $interactive && declare -F ui_run_spinner >/dev/null; then
        if ! ui_run_spinner 'Downloading LazyVim plugins' nvim --headless '+Lazy! sync' +qa; then
            warnings+=('LazyVim plugin sync failed; run nvim and execute :Lazy sync')
        fi
    elif ! nvim --headless '+Lazy! sync' +qa; then
        warnings+=('LazyVim plugin sync failed; run nvim and execute :Lazy sync')
    fi
}

regenerate_nushell_caches() {
    is_selected nushell || return 0
    if $dry_run; then
        command -v starship >/dev/null 2>&1 && describe "Regenerate $config_root/nushell/dotfiles-init/starship.nu"
        command -v zoxide >/dev/null 2>&1 && describe "Regenerate $config_root/nushell/dotfiles-init/zoxide.nu"
        return 0
    fi
    ensure_external_root
    if command -v starship >/dev/null 2>&1; then
        starship init nu >"$external_root/starship.nu"
        install_item nushell "$external_root/starship.nu" "$config_root/nushell/dotfiles-init/starship.nu"
    fi
    if command -v zoxide >/dev/null 2>&1; then
        zoxide init nushell >"$external_root/zoxide.nu"
        install_item nushell "$external_root/zoxide.nu" "$config_root/nushell/dotfiles-init/zoxide.nu"
    fi
}

validate_default_shell() {
    [[ $default_shell != keep ]] || return 0
    if ! $dry_run && ! $install_packages && ! command -v "${module_command[$default_shell]}" >/dev/null 2>&1; then
        printf 'Selected login shell %s is missing. Install it first or use --install-packages.\n' "$default_shell" >&2
        return 1
    fi
}

configure_default_shell() {
    [[ $default_shell != keep ]] || return 0
    local shell_path current_shell account allowed registered=false
    shell_path=$(command -v "${module_command[$default_shell]}" 2>/dev/null || true)
    if $dry_run; then
        describe "Set default shell -> ${shell_path:-$default_shell (after package installation)}"
        return 0
    fi
    if [[ ! -x $shell_path ]] || ! command -v chsh >/dev/null 2>&1; then
        warnings+=("Cannot set $default_shell as login shell: executable or chsh is unavailable")
        return 0
    fi
    shell_path=$(realpath -- "$shell_path")
    account=$(id -un)
    current_shell=$(getent passwd "$account" | cut -d: -f7)
    if [[ ${current_shell##*/} == "${shell_path##*/}" && $(realpath -m -- "$current_shell") == "$shell_path" ]]; then
        describe "$default_shell is already the default shell"
        return 0
    fi
    while IFS= read -r allowed; do
        [[ $allowed == /* && -x $allowed ]] || continue
        if [[ ${allowed##*/} == "${shell_path##*/}" && $(realpath -- "$allowed") == "$shell_path" ]]; then
            registered=true
            shell_path=$allowed
            break
        fi
    done < /etc/shells
    if ! $registered; then
        warnings+=("$shell_path is not registered in /etc/shells; login shell unchanged")
        return 0
    fi
    # This account change is deliberately after config validation/commit.
    # Never invoke sudo or change another user's shell.
    describe "Changing login shell for $account; chsh may request your password"
    if chsh -s "$shell_path"; then
        describe "Default shell set to $default_shell; log out and back in to use it"
    else
        warnings+=("Could not set $default_shell as login shell; run chsh -s $shell_path manually")
    fi
}

validate_installed_configs() {
    local component config
    for component in "${module_names[@]}"; do
        is_selected "$component" || continue
        component_was_applied "$component" || continue
        case "$component" in
            bash) [[ -f $HOME/.bashrc ]] || return 1 ;;
            prism)
                [[ -x $HOME/.local/bin/prism && -x $config_root/prism/prism.py &&
                   -f $config_root/prism/init.sh &&
                   -f $config_root/prism/current ]] || return 1
                ;;
            zsh) [[ -f $HOME/.zshrc ]] || return 1 ;;
            starship)
                for config in bash fish nushell zsh; do
                    [[ -f $config_root/starship/$config.toml ]] || return 1
                done
                ;;
            ssh) [[ -f $HOME/.ssh/config.d/dotfiles.conf ]] || return 1 ;;
            hypr)
                [[ -f $config_root/hypr/hyprland.lua && -f $config_root/hypr/hyprpaper.conf &&
                   -f $config_root/hypr/config/colors.lua && -f $config_root/matugen/config.toml ]] || return 1
                [[ -x $HOME/.local/bin/battery-guardian ]] || return 1
                if ! is_selected kairo-shell; then
                    [[ -f $config_root/quickshell/hyprland-notifications/shell.qml ]] || return 1
                fi
                ;;
            waybar)
                if ! is_selected kairo-shell; then
                    [[ -f $config_root/waybar/config.jsonc &&
                       -f $kairo_shell_data/fonts/archnemesis/Waycat.ttf ]] || return 1
                fi
                ;;
            kairo-shell)
                [[ -x $kairo_shell_target/bin/kairod && -f $kairo_shell_target/src/version.txt &&
                   -L $kairo_shell_bin/kairo && -L $kairo_shell_bin/kairod &&
                   -f $config_root/kairo/settings.json ]] || return 1
                ;;
            kitty-smooth)
                [[ -x $HOME/.local/kitty-smooth/bin/kitty && -x $HOME/.local/bin/kitty-smooth &&
                   -f $kairo_shell_data/applications/kitty-smooth.desktop ]] || return 1
                ;;
            wezterm)
                [[ -f $config_root/wezterm/wezterm.lua ]] || return 1
                for config in config colors events utils; do
                    [[ -d $config_root/wezterm/$config ]] || return 1
                done
                ;;
        esac
    done
}

system_value() {
    local key=$1 value='unknown'
    case "$key" in
        os) value=$(uname -s) ;;
        distribution)
            if [[ -r /etc/os-release ]]; then
                value=$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-${ID:-Linux}}")
            fi
            ;;
        architecture) value=$(uname -m) ;;
        shell) value=${SHELL:-unknown} ;;
        terminal) value=${TERM_PROGRAM:-${TERM:-unknown}} ;;
        session) value=${XDG_SESSION_TYPE:-unknown} ;;
        pacman) command -v pacman >/dev/null 2>&1 && value=available || value=missing ;;
        yay) command -v yay >/dev/null 2>&1 && value=available || value=missing ;;
        systemd) command -v systemctl >/dev/null 2>&1 && value=available || value=missing ;;
    esac
    printf '%s' "$value"
}

interactive_prepare() {
    local -a choices=() profile_choices=()
    local index profile selected_list='' missing_list='' replacement_list='' key target
    ui_start
    local welcome='Your Arch Linux CLI and Hyprland workstation.'
    welcome+=$'\n\n1. Check your system\n2. Choose configs and development tools\n3. Review changes before installation\n\n'
    if $dry_run; then welcome+=$'PREVIEW MODE: no persistent changes.\n'; fi
    if $no_backup; then
        welcome+=$'Backups disabled; automatic rollback stays enabled.\n'
    else
        welcome+=$'Existing configs are backed up; failed installs roll back.\n'
    fi
    welcome+=$'Packages are installed only when you choose to install them.\nYour personal Git and SSH data stays untouched.'
    ui_review "$welcome" 'Welcome to Kairo' begin || exit 130

    local system_details
    printf -v system_details 'Distribution: %s\nArchitecture: %s\nSession: %s\nShell: %s\nTerminal: %s\n\nHome: %s\nConfig root: %s\n\nGPU: %s\nGPU packages: %s\n\npacman: %s\nAUR helper (%s): %s\nsystemd: %s' \
        "$(system_value distribution)" "$(system_value architecture)" \
        "$(system_value session)" "$(system_value shell)" "$(system_value terminal)" \
        "$HOME" "$config_root" "$gpu_description" "${gpu_packages[*]:-none}" \
        "$(system_value pacman)" "$aur_helper" "$(command -v "$aur_helper" >/dev/null 2>&1 && printf available || printf missing)" \
        "$(system_value systemd)"
    ui_review "$system_details" 'Your system' continue || exit 130

    if ! $install_wallpapers; then
        ui_confirm 'Include wallpapers without Hyprland?' \
            "Hyprland already includes the full wallpaper collection. Fresh installs use snow-pine-forest.png. Images go into $HOME/Pictures/Wallpapers." && install_wallpapers=true
    fi
    if ((${#gpu_packages[@]})); then
        ui_confirm 'Install the detected GPU drivers?' \
            "Detected: $gpu_description. Packages: ${gpu_packages[*]}. Uses Arch packages; leaves Xorg configuration unchanged." && { install_gpu_drivers=true; install_packages=true; }
    fi

    for ((index=0; index<${#module_names[@]}; index++)); do
        choices[index]=${module_default[${module_names[index]}]}
    done
    ui_select_modules module_names module_labels module_categories choices || exit 130
    only=()
    for ((index=0; index<${#module_names[@]}; index++)); do
        [[ ${choices[index]} == true ]] && only+=("${module_names[index]}")
    done
    ((${#only[@]})) || { ui_failure 'No modules selected.'; exit 2; }

    for ((index=0; index<${#profile_names[@]}; index++)); do
        profile_choices[index]=false
        for profile in "${profiles[@]}"; do
            [[ $profile == "${profile_names[index]}" ]] && profile_choices[index]=true
        done
    done
    ui_select_default_shell default_shell || exit 130

    ui_select_modules profile_names profile_labels profile_categories profile_choices 'Choose development tools' || exit 130
    profiles=()
    for ((index=0; index<${#profile_names[@]}; index++)); do
        [[ ${profile_choices[index]} == true ]] && profiles+=("${profile_names[index]}")
    done

    collect_missing_packages
    if ((${#missing_aur_packages[@]})); then
        ui_select_aur_helper aur_helper || exit 130
        collect_missing_packages
    fi
    if ! $enable_chaotic_aur; then
        ui_confirm 'Enable Chaotic-AUR?' \
            'Optional third-party binary packages. Imports its signing key and modifies /etc/pacman.conf. Press Enter to keep your current repositories.' && enable_chaotic_aur=true
    fi
    if $enable_chaotic_aur || ((${#profiles[@]})); then install_packages=true; fi

    for index in "${module_names[@]}"; do
        is_selected "$index" || continue
        if [[ $index == waybar ]] && is_selected kairo-shell; then continue; fi
        selected_list+="  • $(module_label "$index")"$'\n'
    done
    if is_selected hypr && ! is_selected kairo-shell; then
        selected_list+=$'  Hyprland includes Waybar, fonts, Hyprlock, Matugen and Quickshell notifications.\n'
        selected_list+=$'  Rofi is seeded only when absent.\n'
    elif is_selected kairo-shell && is_selected waybar; then
        selected_list+=$'  Kairo Shell selected: Waybar deployment is skipped.\n'
    fi
    if ((${#profiles[@]})); then
        selected_list+=$'\n  Package profiles\n'
        for profile in "${profiles[@]}"; do selected_list+="  • $profile"$'\n'; done
    fi
    ((${#missing_official_packages[@]})) && missing_list+="  official: ${missing_official_packages[*]}"$'\n'
    ((${#missing_aur_packages[@]})) && missing_list+="  AUR: ${missing_aur_packages[*]}"$'\n'
    [[ -n $missing_list ]] || missing_list='  none'
    for index in "${module_names[@]}"; do
        is_selected "$index" || continue
        case "$index" in
            bash) [[ -e $HOME/.bashrc ]] && replacement_list+="  $HOME/.bashrc"$'\n' ;;
            zsh) [[ -e $HOME/.zshrc ]] && replacement_list+="  $HOME/.zshrc"$'\n' ;;
            hypr)
                for target in hypr hyprlock matugen; do
                    if [[ -e $config_root/$target || -L $config_root/$target ]]; then
                        replacement_list+="  $config_root/$target"$'\n'
                    fi
                done
                ;;
            kitty-smooth)
                replacement_list+="  $HOME/.local/kitty-smooth"$'\n'"  $HOME/.local/bin/kitty-smooth"$'\n'
                replacement_list+="  $kairo_shell_data/applications/kitty-smooth.desktop"$'\n'
                ;;
            plymouth)
                replacement_list+=$'  /usr/share/plymouth/themes/lone\n  /etc/plymouth/plymouthd.conf\n  initramfs (mkinitcpio, if available)\n'
                ;;
            sddm)
                replacement_list+=$'  /usr/share/sddm/themes/archnemesis\n  /etc/sddm.conf.d/zz-archnemesis.conf\n'
                [[ ! -f /etc/sddm.conf ]] || replacement_list+=$'  /etc/sddm.conf [Theme]\n'
                ;;
            waybar) ;; # Includes fonts; listed together below.
            kairo-shell)
                replacement_list+="  $kairo_shell_target"$'\n'"  $kairo_shell_bin/{kairo,kairod}"$'\n'
                replacement_list+="  $kairo_shell_state/version"$'\n'
                replacement_list+="  $kairo_shell_data/applications/kairo.desktop"$'\n'
                replacement_list+="  $kairo_shell_data/icons/hicolor/scalable/apps/kairo.svg"$'\n'
                ;;
            ssh) [[ -e $HOME/.ssh/config.d/dotfiles.conf ]] && replacement_list+="  $HOME/.ssh/config.d/dotfiles.conf"$'\n' ;;
            *) [[ -e $config_root/$index ]] && replacement_list+="  $config_root/$index"$'\n' ;;
        esac
    done
    if is_selected sddm; then
        selected_list+=$'  SDDM: system theme installation (sudo), mandatory rollback backup.\n'
        selected_list+=$'  Does not enable or restart the display manager.\n'
    fi
    if is_selected waybar && ! is_selected kairo-shell; then
        for target in "$config_root/waybar" "$kairo_shell_data/fonts/archnemesis"; do
            if [[ -e $target || -L $target ]]; then replacement_list+="  $target"$'\n'; fi
        done
    fi
    [[ -n $replacement_list ]] || replacement_list='  none'

    if ! $install_packages && ((${#missing_official_packages[@]} || ${#missing_aur_packages[@]})); then
        ui_confirm 'Install the missing packages?' "$missing_list" && install_packages=true
    fi
    local review
    printf -v review 'Selected modules\n%s\nMissing packages\n%s\n\nManaged targets being replaced\n%s\n\nBackups: %s\nConfig root: %s\nLogin shell: %s\nAUR helper: %s\nInstall packages: %s\nChaotic-AUR: %s\nWallpapers: %s\nDry run: %s' \
        "$selected_list" "$missing_list" "$replacement_list" \
        "$($no_backup && printf disabled || printf enabled)" "$config_root" \
        "$default_shell" "$aur_helper" "$install_packages" "$enable_chaotic_aur" \
        "$install_wallpapers" "$dry_run"
    local review_action=install
    $dry_run && review_action=preview
    ui_review "$review" 'Review installation' "$review_action" || exit 130
}

# Reviewed patch and Kitty base; updates must explicitly change these pins.
kitty_smooth_patch_commit='7a12c832f11bdf10edd4280f1e4f3cd750210a0e'
kitty_smooth_patch_sha256='9932e8542edf5421ef326b9ba9434e925141cb38ab92e98386cb05f1ffd9411d'
kitty_smooth_kitty_tag='v0.49.2'
kitty_smooth_kitty_commit='b2cb871254fbdac19a085188813c8dfb258b95cd'
declare -a kitty_smooth_packages=(
    kitty git python go gcc pkgconf curl openssl xxhash libpng lcms2 cairo harfbuzz
    libglvnd libx11 libxrandr libxinerama libxcursor libxkbcommon libxkbcommon-x11
    dbus wayland wayland-protocols simde shader-slang ttf-nerd-fonts-symbols-mono
    fontconfig ncurses
)

preflight_kitty_smooth() {
    is_selected kitty-smooth || return 0
    local target
    for target in "$HOME/.local/kitty-smooth" "$HOME/.local/bin/kitty-smooth" \
        "$kairo_shell_data/applications/kitty-smooth.desktop" "$config_root/kitty"; do
        assert_safe_destination "$target"
    done
    [[ -x $repo_root/.local/bin/kitty-smooth && -f $repo_root/.config/scripts/kitty-smooth-config.py ]]
}

install_kitty_smooth() {
    is_selected kitty-smooth || return 0
    local checkout payload patch tool desktop current=false
    local expected_build
    expected_build=$(printf 'kitty=%s\npatch=%s\n' "$kitty_smooth_kitty_commit" "$kitty_smooth_patch_commit")
    payload="$HOME/.local/kitty-smooth"
    if ! $rebuild_kitty_smooth && [[ -x $payload/bin/kitty && -f $payload/.kairo-build ]] &&
        [[ $(cat "$payload/.kairo-build") == "$expected_build" ]]; then
        current=true
    fi
    if $dry_run && ! $current; then
        describe "Build Kitty Smooth: Kitty $kitty_smooth_kitty_tag ($kitty_smooth_kitty_commit), patch $kitty_smooth_patch_commit"
        describe "Install kitty-smooth transactionally -> $HOME/.local/kitty-smooth"
        describe "Install launcher -> $HOME/.local/bin/kitty-smooth (stock Kitty fallback)"
        describe "Install desktop entry -> $kairo_shell_data/applications/kitty-smooth.desktop"
        record_installed kitty-smooth
        return 0
    fi
    if $current; then
        describe "Kitty Smooth pinned build already current"
        record_current kitty-smooth
    elif ! $dry_run; then
        for tool in git python3 go cc pkg-config curl slangc fc-list tic; do
            command -v "$tool" >/dev/null || {
                printf 'Kitty Smooth requires %s; rerun with --install-packages.\n' "$tool" >&2; return 1;
            }
        done
        pkg-config --exists libcrypto libxxhash libpng lcms2 cairo-fc harfbuzz gl x11 x11-xcb \
            xrandr xinerama xcursor xkbcommon xkbcommon-x11 dbus-1 wayland-client \
            wayland-cursor wayland-scanner wayland-protocols || {
            echo 'Missing Kitty build libraries; rerun with --install-packages.' >&2; return 1;
        }
        printf '#include <simde/x86/sse4.2.h>\n' | cc -E -x c - >/dev/null || {
            echo 'Missing simde headers; rerun with --install-packages.' >&2; return 1;
        }
        ensure_external_root
        checkout="$external_root/kitty-smooth-source"
        payload="$external_root/kitty-smooth-payload"
        patch="$external_root/kitty-smooth.patch"
        describe "Building Kitty Smooth $kitty_smooth_kitty_tag; this may take several minutes"
        git clone --depth 1 --branch "$kitty_smooth_kitty_tag" https://github.com/kovidgoyal/kitty.git "$checkout"
        [[ $(git -C "$checkout" rev-parse HEAD) == "$kitty_smooth_kitty_commit" ]] || {
            printf 'Kitty source does not match the reviewed commit.\n' >&2; return 1;
        }
        curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
            "https://raw.githubusercontent.com/SunqdXX/kitty-smooth-cursor/$kitty_smooth_patch_commit/kitty-smooth-cursor.patch" -o "$patch"
        [[ $(sha256sum "$patch" | cut -d ' ' -f 1) == "$kitty_smooth_patch_sha256" ]] || {
            printf 'Kitty Smooth patch checksum mismatch.\n' >&2; return 1;
        }
        git -C "$checkout" apply --check "$patch"
        git -C "$checkout" apply "$patch"
        # The source package looks up SymbolsNFM through fontconfig. No remote fonts
        # or compiler binaries are downloaded; Arch packages supply those inputs.
        mkdir -p "$checkout/docs/_build/html" "$checkout/docs/_build/man"
        (
            cd -- "$checkout"
            python3 setup.py linux-package --prefix "$payload" --update-check-interval=0
        )
        [[ -x $payload/bin/kitty ]] || { echo 'Kitty Smooth build produced no executable.' >&2; return 1; }
        "$payload/bin/kitty" --version
        printf 'kitty=%s\npatch=%s\n' "$kitty_smooth_kitty_commit" "$kitty_smooth_patch_commit" > "$payload/.kairo-build"
    fi
    if $dry_run; then
        describe "Check Kitty Smooth launcher and desktop entry"
        return 0
    fi
    ensure_external_root
    desktop="$external_root/kitty-smooth.desktop"
    python3 - "$HOME/.local/bin/kitty-smooth" "$desktop" <<'PY'
from pathlib import Path
import sys
# Desktop Exec is not shell syntax; quote reserved characters, then escape
# backslashes for the desktop-file string parser. Percent signs are field codes.
arg = sys.argv[1].replace('%', '%%')
for char in ('\\', '"', '`', '$'):
    arg = arg.replace(char, '\\' + char)
arg = arg.replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '\\r')
Path(sys.argv[2]).write_text(
    '[Desktop Entry]\nType=Application\nName=Kitty Smooth\n'
    'GenericName=Terminal emulator\nComment=Kitty with smooth cursor motion\n'
    f'Exec="{arg}"\nIcon=kitty\nTerminal=false\nCategories=System;TerminalEmulator;\n'
)
PY
    # Only deploy after source validation, patching and compilation succeed.
    install_item kitty-smooth "$payload" "$HOME/.local/kitty-smooth"
    install_item kitty-smooth "$repo_root/.local/bin/kitty-smooth" "$HOME/.local/bin/kitty-smooth"
    install_item kitty-smooth "$desktop" "$kairo_shell_data/applications/kitty-smooth.desktop"
}


detect_gpu_drivers
if $interactive; then
    interactive_prepare
else
    collect_missing_packages
fi
validate_kairo_shell_destinations
preflight_desktop
validate_default_shell
acquire_privileges

if $interactive; then
    ui_heading
    ui_stage 1 7 'Preparing'
else
    describe '[1/7] Preparing'
fi

if $interactive; then ui_stage 2 7 'Backing up existing targets during replacement'; else describe '[2/7] Backups prepared on demand'; fi
if $interactive; then ui_stage 3 7 'Installing packages'; else describe '[3/7] Installing packages'; fi
enable_chaotic_repository
install_missing_packages
collect_missing_packages
if $interactive; then ui_stage 4 7 'Installing configurations'; else describe '[4/7] Installing configs'; fi

if [[ -f $source_config_root/bash/.bashrc ]]; then
    install_item bash "$source_config_root/bash/.bashrc" "$HOME/.bashrc"
elif is_selected bash; then
    skipped+=(bash)
fi
install_item zsh "$source_config_root/zsh/.zshrc" "$HOME/.zshrc"
install_item zsh "$source_config_root/zsh" "$config_root/zsh"
install_seed_item zsh "$source_config_root/starship/zsh.toml" "$config_root/starship/zsh.toml"
install_item nushell "$source_config_root/nushell/config.nu" "$config_root/nushell/config.nu"
install_seed_item nushell "$source_config_root/nushell/dotfiles-init/starship.nu" "$config_root/nushell/dotfiles-init/starship.nu"
install_seed_item nushell "$source_config_root/nushell/dotfiles-init/zoxide.nu" "$config_root/nushell/dotfiles-init/zoxide.nu"
install_seed_item nushell "$source_config_root/nushell/dotfiles-init/prism.nu" "$config_root/nushell/dotfiles-init/prism.nu"
install_item git "$source_config_root/git/.gitconfig" "$config_root/dotfiles/gitconfig"
install_git_include "$config_root/dotfiles/gitconfig"
install_item lazygit "$source_config_root/lazygit/config.yml" "$config_root/lazygit/config.yml"
install_item broot "$source_config_root/broot" "$config_root/broot"
install_item nvim "$source_config_root/nvim" "$config_root/nvim"
install_item yazi "$source_config_root/yazi" "$config_root/yazi"
install_item fastfetch "$source_config_root/fastfetch" "$config_root/fastfetch"
install_item btop "$source_config_root/btop" "$config_root/btop"
install_item oh-my-posh "$source_config_root/oh-my-posh/amro.omp.json" "$config_root/oh-my-posh/amro.omp.json"
if [[ -f $source_config_root/starship/bash.toml &&
      -f $source_config_root/starship/fish.toml &&
      -f $source_config_root/starship/nushell.toml &&
      -f $source_config_root/starship/zsh.toml ]]; then
    install_item starship "$source_config_root/starship" "$config_root/starship"
elif is_selected starship; then
    skipped+=(starship)
    warnings+=('Starship source directory is incomplete; skipped Starship configuration')
fi
install_item atuin "$source_config_root/atuin/config.toml" "$config_root/atuin/config.toml"
install_item bat "$source_config_root/bat/config" "$config_root/bat/config"
install_item bat "$source_config_root/bat/themes" "$config_root/bat/themes"
install_item cava "$source_config_root/cava/config" "$config_root/cava/config"
install_item ssh "$source_config_root/ssh/config" "$HOME/.ssh/config.d/dotfiles.conf"
install_include_line ssh "$HOME/.ssh/config" 'Include ~/.ssh/config.d/*.conf'
install_kitty_smooth
install_kitty
if is_selected wezterm && [[ -e $HOME/.wezterm.lua || -L $HOME/.wezterm.lua ]]; then
    skipped+=(wezterm)
    warnings+=('WezTerm deployment skipped: move ~/.wezterm.lua aside before installing the XDG configuration')
else
    install_item wezterm "$source_config_root/wezterm" "$config_root/wezterm"
fi
install_curated_wallpapers
install_hypr_desktop
install_waybar
install_item rofi "$source_config_root/rofi" "$config_root/rofi"
if is_selected hypr && ! is_selected kairo-shell && ! $dry_run && [[ ${CI:-false} != true ]]; then
    if ! "$config_root/hypr/scripts/apply-wallpaper-theme.sh"; then
        warnings+=('Could not generate the wallpaper palette; the bundled colors remain active')
    fi
fi
install_kairo_shell
if [[ -d $source_config_root/fish ]]; then
    fish_source="$source_config_root/fish"
    fish_stage=''
    if is_selected fish && is_selected prism && [[ -f $config_root/fish/conf.d/15-prism-theme.fish ]]; then
        ensure_external_root
        fish_stage="$external_root/fish-config"
        mkdir -p -- "$fish_stage"
        cp -a -- "$source_config_root/fish" "$fish_stage/fish"
        install -D -m 644 -- "$config_root/fish/conf.d/15-prism-theme.fish" \
            "$fish_stage/fish/conf.d/15-prism-theme.fish"
        fish_source="$fish_stage/fish"
    fi
    install_item fish "$fish_source" "$config_root/fish"
    install_seed_item fish "$source_config_root/starship/fish.toml" "$config_root/starship/fish.toml"
elif is_selected fish; then
    skipped+=(fish)
fi
install_item prism "$source_config_root/prism/prism.py" "$config_root/prism/prism.py"
install_item prism "$source_config_root/prism/README.md" "$config_root/prism/README.md"
install_item prism "$source_config_root/prism/init.sh" "$config_root/prism/init.sh"
install_seed_item prism "$source_config_root/prism/current" "$config_root/prism/current"
install_seed_item prism "$source_config_root/prism/theme.sh" "$config_root/prism/theme.sh"
install_seed_item prism "$source_config_root/prism/fzf.txt" "$config_root/prism/fzf.txt"
install_seed_item prism "$source_config_root/prism/nu-colors.json" "$config_root/prism/nu-colors.json"
install_item prism "$repo_root/.local/bin/prism" "$HOME/.local/bin/prism"

if $interactive; then ui_stage 5 7 'Configuring shells'; else describe '[5/7] Configuring shells'; fi
install_zsh_integrations
install_zsh_plugins

if is_selected git && ! $dry_run && command -v git >/dev/null 2>&1; then
    # Enforce the repository's Linux line-ending policy.
    git config --file "$config_root/dotfiles/gitconfig" core.autocrlf input
    git config --file "$config_root/dotfiles/gitconfig" core.eol lf
fi

if is_selected ssh && ! $dry_run && [[ -f $HOME/.ssh/config ]]; then
    chmod 700 "$HOME/.ssh"
    chmod 700 "$HOME/.ssh/config.d"
    chmod 600 "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config.d/dotfiles.conf"
fi

if $interactive; then ui_stage 6 7 'Rebuilding generated caches'; else describe '[6/7] Rebuilding caches'; fi
regenerate_nushell_caches
if is_selected waybar && ! is_selected kairo-shell && ! $dry_run && command -v fc-cache >/dev/null 2>&1; then
    fc-cache "$kairo_shell_data/fonts/archnemesis"
fi
if is_selected bat && ! $dry_run && command -v bat >/dev/null 2>&1; then bat cache --build; fi
install_lazyvim_plugins

if $interactive; then ui_stage 7 7 'Validating installation'; else describe '[7/7] Validating'; fi
if ! $dry_run; then validate_installed_configs; fi

# Apply system themes only after home configurations validate.
if is_selected sddm; then
    sddm_args=()
    if $dry_run; then
        sddm_args+=(--dry-run)
    else
        ensure_external_root
        sddm_receipt="$external_root/sddm-receipt"
        # Create as the invoking user so sudo's umask cannot hide the receipt.
        (umask 077; : > "$sddm_receipt")
        sddm_args+=(--receipt "$sddm_receipt")
    fi
    bash "$repo_root/.local/share/sddm/themes/archnemesis/install.sh" "${sddm_args[@]}"
    record_installed sddm
fi

if is_selected plymouth; then
    plymouth_args=()
    $dry_run && plymouth_args+=(--dry-run)
    bash "$repo_root/.local/share/plymouth/install.sh" "${plymouth_args[@]}"
    record_installed plymouth
fi

if ! $dry_run; then
    commit_transaction
    sddm_receipt=''
    chaotic_config_changed=false
fi

configure_default_shell

summary_label=Installed
$dry_run && summary_label=Planned
printf '\n%s: %s\n' "$summary_label" "${installed[*]:-nothing}"
if ((${#already_current[@]})); then
    printf 'Already current: %s\n' "${already_current[*]}"
fi
if ((${#skipped[@]})); then
    printf 'Skipped: %s\n' "${skipped[*]}"
fi
if ! $no_backup && [[ -n $backup_root && -d $backup_root ]]; then
    printf 'Backups: %s\n' "$backup_root"
fi
if ((${#warnings[@]})); then
    printf 'Warnings:\n'
    printf '  - %s\n' "${warnings[@]}"
fi
if $dry_run; then
    printf 'Preview complete. No changes were made. Run again without --dry-run to install.\n'
else
    printf 'Done. Restart your shell and configured applications.\n'
fi
if $interactive && declare -F ui_success >/dev/null; then
    success_details="  $summary_label       ${installed[*]:-nothing}"
    if ((${#already_current[@]})); then success_details+=$'\n'"  Already current ${already_current[*]}"; fi
    if ((${#skipped[@]})); then success_details+=$'\n'"  Skipped         ${skipped[*]}"; fi
    if [[ -n $backup_root ]]; then success_details+=$'\n'"  Backups         $backup_root"; fi
    if ((${#warnings[@]})); then success_details+=$'\n'"  Warnings        ${warnings[*]}"; fi
    if $dry_run; then
        success_details+=$'\n\n'"  No changes were made. Run again without --dry-run to install."
    else
        success_details+=$'\n\n'"  Restart your shell to load the new environment."
    fi
    completion_title='INSTALLATION COMPLETE'
    $dry_run && completion_title='DRY RUN COMPLETE'
    ui_success "$success_details" "$completion_title"
fi
