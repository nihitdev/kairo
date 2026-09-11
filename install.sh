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
make_fish_default=false
enable_chaotic_aur=false
aur_helper=paru
install_gpu_drivers=false
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

declare -a module_names=(
    bash fish nushell zsh starship atuin bat broot yazi lazygit fastfetch
    git nvim kitty cava ssh oh-my-posh hypr kairo-shell rofi wezterm
)
declare -a module_labels=(
    Bash Fish Nushell Zsh Starship Atuin Bat Broot Yazi LazyGit Fastfetch
    Git Neovim Kitty Cava SSH 'Oh My Posh' Hyprland 'Kairo Shell' Rofi WezTerm
)
declare -a module_categories=(
    Shells Shells Shells Shells Shells CLI CLI CLI CLI CLI CLI
    Development Development Desktop Desktop System Shells Desktop Desktop Desktop Desktop
)
declare -A module_default=(
    [bash]=true [fish]=true [nushell]=true [zsh]=true [starship]=true
    [atuin]=true [bat]=true [broot]=true [yazi]=true [lazygit]=true
    [fastfetch]=true [git]=true [nvim]=true [kitty]=true [cava]=true
    [ssh]=true [oh-my-posh]=false [hypr]=false [kairo-shell]=false [rofi]=false [wezterm]=true
)
declare -A module_package=(
    [bash]=bash [fish]=fish [nushell]=nushell [zsh]=zsh [starship]=starship
    [atuin]=atuin [bat]=bat [broot]=broot [yazi]=yazi [lazygit]=lazygit
    [fastfetch]=fastfetch [git]=git [nvim]=neovim [kitty]=kitty [cava]=cava [wezterm]=wezterm
    [ssh]=openssh [hypr]=hyprland [rofi]=rofi-wayland
)
declare -A module_aur_package=([oh-my-posh]=oh-my-posh-bin)
declare -A module_command=(
    [bash]=bash [fish]=fish [nushell]=nu [zsh]=zsh [starship]=starship
    [atuin]=atuin [bat]=bat [broot]=broot [yazi]=yazi [lazygit]=lazygit
    [fastfetch]=fastfetch [git]=git [nvim]=nvim [kitty]=kitty [cava]=cava [wezterm]=wezterm
    [ssh]=ssh [oh-my-posh]=oh-my-posh [hypr]=Hyprland [rofi]=rofi
)
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
    [containers]='docker docker-compose podman buildah'
    [wayland]='xdg-desktop-portal-hyprland wl-clipboard grim slurp swappy brightnessctl playerctl ddcutil libnotify'
    [media]='pipewire pipewire-pulse wireplumber ffmpeg imagemagick yt-dlp'
)

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run          Show what would change without writing files
  --no-backup        Replace existing files without backing them up
  --install-packages Install missing selected packages with pacman and paru/yay
  --profile NAME     Install an optional package profile; repeatable
                     Profiles: core-build cpp rust python web containers wayland media all
  --aur-helper NAME  Use paru (default) or yay for AUR packages
  --enable-chaotic-aur
                     Enable the third-party Chaotic-AUR binary repository
  --install-gpu-drivers
                     Install reviewed Arch drivers for detected GPUs
  --only NAME        Install one specific component; repeat for multiple tools
                     Use --only all to install every supported component
  -h, --help         Show this help

Components:
  bash zsh nushell git lazygit broot nvim yazi fastfetch oh-my-posh
  starship atuin bat cava ssh kitty fish hypr kairo-shell rofi wezterm all
EOF
}

while (($#)); do
    case "$1" in
        --dry-run)
            dry_run=true
            ;;
        --no-backup)
            no_backup=true
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
if [[ -t 0 && -t 1 && ${CI:-false} != true && ${#only[@]} -eq 0 ]] &&
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
    kairo_checkout="$HOME/kairo"
    if [[ -t 1 && ${CI:-false} != true && -r /dev/tty ]]; then
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
    if [[ -t 1 && ${CI:-false} != true && ${#only[@]} -eq 0 && -r /dev/tty ]]; then
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
    local status=$? failed_command=${BASH_COMMAND:-unknown}
    trap - ERR INT TERM
    rollback_transaction
    rollback_system_changes
    if $interactive && declare -F ui_failure >/dev/null; then
        ui_failure "Command: $failed_command (exit $status). Completed config replacements were rolled back."
        printf '\nPress any key to exit.'
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
        command_name=${module_command[$component]:-}
        if [[ -n ${module_package[$component]:-} ]]; then
            package=${module_package[$component]}
            package_is_installed "$package" "$command_name" || record_unique missing_official_packages "$package"
        elif [[ -n ${module_aur_package[$component]:-} ]]; then
            package=${module_aur_package[$component]}
            package_is_installed "$package" "$command_name" || record_unique missing_aur_packages "$package"
        fi
    done
    if is_selected zsh; then
        for package in zsh-autosuggestions zsh-syntax-highlighting; do
            package_is_installed "$package" || record_unique missing_official_packages "$package"
        done
        package_is_installed git git || record_unique missing_official_packages git
    fi
    if is_selected bash || is_selected fish || is_selected nushell; then
        package_is_installed zoxide zoxide || record_unique missing_official_packages zoxide
    fi
    if is_selected fish; then
        package_is_installed fzf fzf || record_unique missing_official_packages fzf
        package_is_installed curl curl || record_unique missing_official_packages curl
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
        printf '\n  Kairo needs administrator access for the reviewed package changes.\n'
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

install_hypr_desktop() {
    is_selected hypr || return 0
    local hypr_source="$source_config_root/hypr"
    if ! is_selected kairo-shell; then
        install_item hypr "$hypr_source" "$config_root/hypr"
        install_item hypr "$source_config_root/waybar" "$config_root/waybar"
        return 0
    fi

    local line found=false
    while IFS= read -r line || [[ -n $line ]]; do
        [[ $line != '    hl.exec_cmd("waybar")' ]] || found=true
    done < "$hypr_source/hyprland.lua"
    if ! $found; then
        printf 'Kairo: could not locate the Waybar Hyprland startup line.\n' >&2
        return 1
    fi
    describe "Configure Hyprland startup -> $kairo_shell_bin/kairod start"
    describe 'Skip Waybar deployment because Kairo Shell is selected'
    if $dry_run; then
        install_item hypr "$hypr_source" "$config_root/hypr"
        return 0
    fi

    ensure_external_root
    local temp_hypr="$external_root/hypr" command
    cp -a -- "$hypr_source" "$temp_hypr"
    # Quote the executable for the command shell, then escape it for Lua.
    command="'${kairo_shell_bin//\'/\'\\\'\'}/kairod' start"
    command=${command//\\/\\\\}
    command=${command//\"/\\\"}
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == '    hl.exec_cmd("waybar")' ]]; then
            printf '    hl.exec_cmd("%s")\n' "$command"
        else
            printf '%s\n' "$line"
        fi
    done < "$hypr_source/hyprland.lua" > "$temp_hypr/hyprland.lua"
    install_item hypr "$temp_hypr" "$config_root/hypr"
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
    if [[ -r $HOME/.oh-my-zsh/oh-my-zsh.sh ]]; then
        return
    fi
    if ! $install_packages; then
        warnings+=('Oh My Zsh is missing; rerun with --install-packages to install it')
        return
    fi
    if $dry_run; then
        describe "Clone Oh My Zsh -> $HOME/.oh-my-zsh"
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
    install_item zsh "$external_root/oh-my-zsh" "$HOME/.oh-my-zsh"
}

install_fish_integrations() {
    local plugin_manifest="$config_root/fish/fish_plugins"
    is_selected fish || return 0
    $dry_run && plugin_manifest="$source_config_root/fish/fish_plugins"
    [[ -f $plugin_manifest ]] || {
        warnings+=('Fish plugin manifest is missing; skipped Fisher plugins')
        return 0
    }
    if ! $install_packages; then
        warnings+=('Fish plugins were not synced; rerun with --install-packages to install Fisher and plugins')
        return 0
    fi
    if $dry_run; then
        describe "Install Fisher and sync plugins from $plugin_manifest"
        return 0
    fi
    command -v fish >/dev/null 2>&1 || {
        warnings+=('Fish is unavailable; skipped Fisher plugin installation')
        return 0
    }
    if ! fish -c 'type -q fisher'; then
        local fisher_source
        ensure_external_root
        fisher_source="$external_root/fisher.fish"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$fisher_source"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$fisher_source" https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish
        else
            printf 'curl or wget is required to install Fisher.\n' >&2
            return 1
        fi
        fish -c "source '$fisher_source'; and fisher install jorgebucaran/fisher"
    fi
    fish -c 'fisher update'
    describe "Synced Fish plugins from $config_root/fish/fish_plugins"
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

configure_fish_default() {
    $make_fish_default || return 0
    is_selected fish || return 0
    local fish_path current_shell
    fish_path=$(command -v fish 2>/dev/null || true)
    [[ -n $fish_path ]] || { warnings+=('Fish is not installed, so the login shell was not changed'); return; }
    current_shell=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || true)
    if [[ $current_shell == "$fish_path" ]]; then
        describe "Fish is already the default shell"
        return
    fi
    if $dry_run; then
        describe "Set default shell -> $fish_path"
        return
    fi
    grep -Fqx -- "$fish_path" /etc/shells || {
        warnings+=("$fish_path is not listed in /etc/shells; default shell unchanged")
        return
    }
    if chsh -s "$fish_path"; then
        describe "Set default shell -> $fish_path"
    else
        warnings+=("Could not set the default shell to $fish_path; run chsh -s $fish_path manually")
    fi
}

validate_installed_configs() {
    local component config
    for component in "${module_names[@]}"; do
        is_selected "$component" || continue
        component_was_applied "$component" || continue
        case "$component" in
            bash) [[ -f $HOME/.bashrc ]] || return 1 ;;
            zsh) [[ -f $HOME/.zshrc ]] || return 1 ;;
            starship)
                for config in bash fish nushell zsh; do
                    [[ -f $config_root/starship/$config.toml ]] || return 1
                done
                ;;
            ssh) [[ -f $HOME/.ssh/config.d/dotfiles.conf ]] || return 1 ;;
            hypr) [[ -d $config_root/hypr ]] || return 1 ;;
            kairo-shell)
                [[ -x $kairo_shell_target/bin/kairod && -f $kairo_shell_target/src/version.txt &&
                   -L $kairo_shell_bin/kairo && -L $kairo_shell_bin/kairod &&
                   -f $config_root/kairo/settings.json ]] || return 1
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
    local index profile selected_list='' missing_list='' replacement_list='' key
    ui_start
    ui_heading
    $dry_run && ui_status warn 'DRY RUN · no persistent changes will be made'
    ui_card 'Welcome to Kairo' 'A safe, transactional setup for your Arch Linux CLI and Hyprland workstation.'
    ui_status ok 'Backups and automatic rollback enabled'
    ui_status ok 'No packages are installed without confirmation'
    ui_status ok 'Your personal Git and SSH data stays untouched'
    ui_wait_for_enter || exit 130

    ui_heading
    ui_section 'System detection'
    printf '\n'
    ui_kv 'OS' "$(system_value os)"
    ui_kv 'Distribution' "$(system_value distribution)"
    ui_kv 'Architecture' "$(system_value architecture)"
    ui_kv 'Shell' "$(system_value shell)"
    ui_kv 'Home' "$HOME"
    ui_kv 'Config root' "$config_root"
    ui_kv 'Terminal' "$(system_value terminal)"
    ui_kv 'Session' "$(system_value session)"
    ui_kv 'GPU' "$gpu_description"
    if ((${#gpu_packages[@]})); then ui_kv 'GPU packages' "${gpu_packages[*]}"; fi
    printf '\n'
    ui_section 'Arch toolchain'
    printf '\n'
    [[ $(system_value pacman) == available ]] && ui_status ok 'pacman available' || ui_status warn 'pacman unavailable'
    [[ $(system_value yay) == available ]] && ui_status ok 'yay available' || ui_status warn 'yay unavailable · only needed for selected AUR modules'
    [[ $(system_value systemd) == available ]] && ui_status ok 'systemd available' || ui_status warn 'systemd unavailable'
    ui_wait_for_enter || exit 130
    if ((${#gpu_packages[@]})); then
        ui_heading
        ui_section 'Graphics drivers'
        printf '\n  Detected  %s\n' "$gpu_description"
        printf '  Proposed  %s\n\n' "${gpu_packages[*]}"
        printf '  Kairo uses Arch packages only and does not write Xorg configuration.\n\n'
        ui_confirm 'Install these GPU packages?' && { install_gpu_drivers=true; install_packages=true; }
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
    ui_select_modules profile_names profile_labels profile_categories profile_choices || exit 130
    profiles=()
    for ((index=0; index<${#profile_names[@]}; index++)); do
        [[ ${profile_choices[index]} == true ]] && profiles+=("${profile_names[index]}")
    done

    collect_missing_packages
    if ((${#missing_aur_packages[@]})); then
        ui_heading
        ui_section 'AUR helper'
        printf '\n  Select the helper Kairo should use for AUR packages.\n\n'
        printf '  %s[P]%s paru  %s(default, Rust-based)\n' "$UI_CYAN" "$UI_RESET" "$UI_DIM"
        printf '  %s[Y]%s yay   %s(Go-based)%s\n\n' "$UI_CYAN" "$UI_RESET" "$UI_DIM" "$UI_RESET"
        printf '  Choice [P/y]: '
        IFS= read -rsn1 key
        printf '\n'
        [[ $key == y || $key == Y ]] && aur_helper=yay || aur_helper=paru
        collect_missing_packages
    fi
    ui_heading
    ui_section 'Optional binary repository'
    printf '\n  Chaotic-AUR distributes third-party prebuilt AUR packages.\n'
    printf '  Enabling it imports its signing key and modifies /etc/pacman.conf.\n\n'
    ui_confirm 'Enable Chaotic-AUR? This changes system package trust.' && enable_chaotic_aur=true

    for index in "${only[@]}"; do
        selected_list+="  • $(module_label "$index")"$'\n'
    done
    if ((${#profiles[@]})); then
        selected_list+=$'\n  Package profiles\n'
        for profile in "${profiles[@]}"; do selected_list+="  • $profile"$'\n'; done
    fi
    ((${#missing_official_packages[@]})) && missing_list+="  official: ${missing_official_packages[*]}"$'\n'
    ((${#missing_aur_packages[@]})) && missing_list+="  AUR: ${missing_aur_packages[*]}"$'\n'
    [[ -n $missing_list ]] || missing_list='  none'
    for index in "${only[@]}"; do
        case "$index" in
            bash) [[ -e $HOME/.bashrc ]] && replacement_list+="  $HOME/.bashrc"$'\n' ;;
            zsh) [[ -e $HOME/.zshrc ]] && replacement_list+="  $HOME/.zshrc"$'\n' ;;
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
    [[ -n $replacement_list ]] || replacement_list='  none'

    ui_heading
    ui_section 'Review installation'
    printf '\n%sSelected modules%s\n%s\n' "$UI_CYAN" "$UI_RESET" "$selected_list"
    ui_rule
    printf '%sMissing packages%s\n%s\n\n' "$UI_CYAN" "$UI_RESET" "$missing_list"
    printf '%sManaged targets being replaced%s\n%s\n\n' "$UI_CYAN" "$UI_RESET" "$replacement_list"
    ui_rule
    ui_kv 'Backups' "$($no_backup && printf disabled || printf enabled)"
    ui_kv 'Config root' "$config_root"
    ui_kv 'AUR helper' "$aur_helper"
    ui_kv 'Chaotic-AUR' "$($enable_chaotic_aur && printf enabled || printf disabled)"
    $dry_run && ui_kv 'Mode' "${UI_YELLOW}DRY RUN${UI_RESET}"
    if ! $install_packages && ((${#missing_official_packages[@]} || ${#missing_aur_packages[@]})); then
        ui_confirm 'Install missing packages?' && install_packages=true
    fi
    ui_wait_for_enter || exit 130
    is_selected fish && make_fish_default=true
}

detect_gpu_drivers
if $interactive; then
    interactive_prepare
else
    collect_missing_packages
fi
validate_kairo_shell_destinations
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
install_item zsh "$source_config_root/oh-my-zsh/.zshrc" "$HOME/.zshrc"
install_item nushell "$source_config_root/nushell/config.nu" "$config_root/nushell/config.nu"
install_seed_item nushell "$source_config_root/nushell/dotfiles-init/starship.nu" "$config_root/nushell/dotfiles-init/starship.nu"
install_seed_item nushell "$source_config_root/nushell/dotfiles-init/zoxide.nu" "$config_root/nushell/dotfiles-init/zoxide.nu"
install_item git "$source_config_root/git/.gitconfig" "$config_root/dotfiles/gitconfig"
install_git_include "$config_root/dotfiles/gitconfig"
install_item lazygit "$source_config_root/lazygit/config.yml" "$config_root/lazygit/config.yml"
install_item broot "$source_config_root/broot" "$config_root/broot"
install_item nvim "$source_config_root/nvim" "$config_root/nvim"
install_item yazi "$source_config_root/yazi" "$config_root/yazi"
install_item fastfetch "$source_config_root/fastfetch" "$config_root/fastfetch"
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
install_item kitty "$source_config_root/kitty" "$config_root/kitty"
if is_selected wezterm && [[ -e $HOME/.wezterm.lua || -L $HOME/.wezterm.lua ]]; then
    skipped+=(wezterm)
    warnings+=('WezTerm deployment skipped: move ~/.wezterm.lua aside before installing the XDG configuration')
else
    install_item wezterm "$source_config_root/wezterm" "$config_root/wezterm"
fi
install_hypr_desktop
install_item rofi "$source_config_root/rofi" "$config_root/rofi"
install_kairo_shell
if [[ -d $source_config_root/fish ]]; then
    install_item fish "$source_config_root/fish" "$config_root/fish"
elif is_selected fish; then
    skipped+=(fish)
fi

if $interactive; then ui_stage 5 7 'Configuring shells'; else describe '[5/7] Configuring shells'; fi
install_zsh_integrations
install_fish_integrations

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
if is_selected bat && ! $dry_run && command -v bat >/dev/null 2>&1; then bat cache --build; fi
install_lazyvim_plugins

if $interactive; then ui_stage 7 7 'Validating installation'; else describe '[7/7] Validating'; fi
if ! $dry_run; then validate_installed_configs; fi

if ! $dry_run; then
    commit_transaction
    chaotic_config_changed=false
fi

configure_fish_default

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
printf 'Done. Restart your shell and configured applications.\n'
if $interactive && declare -F ui_success >/dev/null; then
    success_details="  Installed       ${installed[*]:-nothing}"
    if ((${#already_current[@]})); then success_details+=$'\n'"  Already current ${already_current[*]}"; fi
    if ((${#skipped[@]})); then success_details+=$'\n'"  Skipped         ${skipped[*]}"; fi
    if [[ -n $backup_root ]]; then success_details+=$'\n'"  Backups         $backup_root"; fi
    if ((${#warnings[@]})); then success_details+=$'\n'"  Warnings        ${warnings[*]}"; fi
    success_details+=$'\n\n'"  Restart your shell to load the new environment."
    completion_title='INSTALLATION COMPLETE'
    $dry_run && completion_title='DRY RUN COMPLETE'
    ui_success "$success_details" "$completion_title"
    ui_footer 'Any key  exit Kairo'
    IFS= read -rsn1 _ || true
    printf '\n'
fi
