<div align="center">

# Kairo

### Arch, composed.

**A safe, interactive workstation installer for Arch Linux, Hyprland, and a CLI-first development setup.**

[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Website](https://img.shields.io/badge/Website-get--kairo.vercel.app-cba6f7)](https://get-kairo.vercel.app)
[![Shell](https://img.shields.io/badge/Installer-Bash-a6e3a1?logo=gnubash&logoColor=11111b)](install.sh)
[![License](https://img.shields.io/github/license/nihitdev/kairo)](LICENSE)

[Website](https://get-kairo.vercel.app) · [Quick start](#quick-start) · [Features](#features) · [Modules](#included-configurations) · [Safety](#safety-first)

</div>

Kairo turns a fresh Arch installation into a configured development workstation without assuming your home directory is disposable.

It combines curated dotfiles, optional package installation, developer toolchains, GPU detection, and a dependency-free terminal UI. Changes are staged before activation, existing configuration can be backed up, and failed transactions roll back instead of leaving half-installed state behind.

> **Preview first. Install second.** `./install.sh --dry-run` performs a zero-write preview of the selected changes.

## Features

- **Interactive installer** — full-screen Bash TUI using standard terminal sequences
- **Selective deployment** — install only the dotfile modules and toolchains you want
- **Arch-native packages** — `pacman` first, with optional Paru or Yay for AUR packages
- **Transactional changes** — staged replacements, private backups, validation, and rollback
- **GPU detection** — reviewed package proposals for Intel, AMD, and modern NVIDIA hardware
- **Developer profiles** — Rust, Python, web, C/C++, containers, Wayland, and media tooling
- **Per-shell prompts** — separate Starship configuration for Bash, Fish, Nushell, and Zsh
- **Curated rice branches** — coordinated Hyprland, Waybar, Kitty, and wallpaper palettes
- **Automation-friendly output** — deterministic plain output outside interactive terminals
- **No surprise upgrades** — Kairo installs what you selected without silently upgrading the whole system

## Quick start

### Remote installer

```sh
curl -fsSL https://raw.githubusercontent.com/nihitdev/kairo/main/install.sh | bash
```

or:

```sh
wget -qO- https://raw.githubusercontent.com/nihitdev/kairo/main/install.sh | bash
```

The remote entry point requests sudo when required, clones Kairo to `~/kairo`, and launches the interactive installer. If a clean checkout already exists, it is updated with a fast-forward pull. Modified or unrelated directories are not overwritten.

### Clone manually

```sh
git clone https://github.com/nihitdev/kairo.git
cd kairo
./install.sh
```

Want to inspect everything before Kairo writes anything?

```sh
./install.sh --dry-run
```

## Installer flow

```text
Welcome → Detect → Dependencies → Modules → Review
        → Backup → Packages → Dotfiles → Configure → Validate → Complete
```

Kairo detects the distribution, architecture, shell, display session, package tools, service manager, and configuration root. The review step shows the selected modules, missing packages, replacement targets, and backup behavior before privileged or destructive work begins.

| Key | Action |
| --- | --- |
| `↑` / `↓` or `J` / `K` | Move |
| `Space` | Toggle item |
| `A` | Select all |
| `N` | Select none |
| `Enter` | Continue |
| `Q` or `Esc` | Cancel safely |

## Common commands

```sh
# Preview one module
./install.sh --dry-run --only starship

# Install selected modules
./install.sh --only yazi --only broot --only starship

# Select every supported dotfile module
./install.sh --only all

# Install missing packages for selected modules
./install.sh --install-packages --only nvim --only yazi

# Add development toolchains
./install.sh --install-packages \
  --profile core-build \
  --profile rust \
  --profile web

# Use Yay instead of the default Paru helper
./install.sh --install-packages --aur-helper yay

# Review and install detected GPU drivers
./install.sh --install-packages --install-gpu-drivers

# Explicitly disable backups
./install.sh --no-backup --only starship
```

Run `./install.sh --help` for the authoritative list of options, modules, and profiles.

## Included configurations

| Area | Modules |
| --- | --- |
| Shells | [Bash](.config/bash/), [Fish](.config/fish/), [Nushell](.config/nushell/), [Zsh + Oh My Zsh](.config/oh-my-zsh/) |
| Prompt & history | [Starship](.config/starship/), [Atuin](.config/atuin/), [Oh My Posh](.config/oh-my-posh/) |
| CLI workflow | [Bat](.config/bat/), [Broot](.config/broot/), [Yazi](.config/yazi/), [LazyGit](.config/lazygit/), [Fastfetch](.config/fastfetch/), [Cava](.config/cava/) |
| Development | [Git](.config/git/), [Neovim](.config/nvim/), [SSH](.config/ssh/) |
| Desktop | [WezTerm](.config/wezterm/), [Kitty](.config/kitty/), [Hyprland](.config/hypr/), [Waybar](.config/waybar/), [Kairo Shell](#kairo-shell) |

Hyprland is deliberately opt-in because replacing compositor configuration can disrupt an active session:

```sh
./install.sh --dry-run --only hypr
```

Third-party snapshots and intentionally duplicated assets are documented in [VENDORED.md](VENDORED.md).

## WezTerm

WezTerm is selected by default and is available in the interactive module picker
and through `--only wezterm`:

```sh
# Preview the configuration deployment
./install.sh --dry-run --only wezterm

# Install the configuration and missing Arch dependencies
./install.sh --install-packages --only wezterm
```

The installer deploys the complete [modular configuration](.config/wezterm/)
to `~/.config/wezterm` (or `$XDG_CONFIG_HOME/wezterm`) using Kairo's transactional
copy, backup, and rollback workflow. Package installation includes `wezterm`,
`zsh` for the configured default shell, and `ttf-jetbrains-mono-nerd` for the font
and UI icons. Packages are only installed with `--install-packages` or when
selected during interactive review.

The configuration retains the 9.75 font size, custom tab bar, left-click new-tab
action, right-click launch menu, colours, keybindings, and status modules.
Personal backdrop images are excluded; the background colour works without
images. To use your own wallpapers, set an external directory with
`set_images_dir` in [wezterm.lua](.config/wezterm/wezterm.lua), before
`scan_images_dir`. An external directory keeps images outside the managed
configuration that the installer replaces.

If `~/.wezterm.lua` exists, Kairo skips WezTerm deployment and reports the
conflict. Move that file aside before installing the XDG configuration.
Upstream attribution and the retained MIT license are documented in
[VENDORED.md](VENDORED.md#wezterm).

## Kairo Shell

The optional `kairo-shell` module installs Kairo Shell `v2.2.0-beta.1`, verified
against commit `64420cb38748b406608af95b2252f60958a8e5a9`. It is unselected by
default; `--only all` includes it.

```sh
# Preview the shell and Hyprland startup integration
./install.sh --dry-run --only hypr --only kairo-shell

# Install the shell, Hyprland configuration, and required packages
./install.sh --install-packages --only hypr --only kairo-shell
```

Selecting both modules replaces the managed Hyprland Waybar startup command
with the installed `kairod start` path and skips Waybar deployment. Selecting
only `hypr` continues to install Waybar. Selecting only `kairo-shell` installs
the shell without changing Hyprland; start it with `~/.local/bin/kairod start`
in a Hyprland session. Installation does not start a daemon or change an active
session.

The installer manages these paths with its normal backup and rollback workflow:

- Application: `${XDG_DATA_HOME:-~/.local/share}/kairo`
- Launchers: `${KAIRO_BIN_DIR:-~/.local/bin}/{kairo,kairod}`
- Settings: `${XDG_CONFIG_HOME:-~/.config}/kairo/settings.json` (created only when absent)
- Version state: `${XDG_STATE_HOME:-~/.local/state}/kairo/version`
- Desktop entry and icon under the XDG data directory

All destinations must resolve inside your home directory. Existing unrelated
launcher files and unmanaged application directories are rejected. Put the
launcher directory first in your session's `PATH`; its `kairo` command controls
the desktop shell. Use `./install.sh` from this checkout for the dotfile installer.

Runtime dependencies from the pinned release are included in Kairo's package
review, including Quickshell, Hyprland, Qt, audio/network utilities, the Iosevka
Nerd Font, and the AUR package `wl-gammarelay-rs`. Installation remains opt-in
through `--install-packages` or interactive review. Without it, missing packages
are reported and must be installed before starting the shell. The upstream
interactive installer, system upgrades, display-manager setup, service changes,
and optional wallpaper downloads are not run.

The downloaded payload retains upstream AGPL-3.0 licensing and attribution.
The [local shell prototype](shell/README.md) is separate from this release.

## Developer toolchains

Profiles are independent from dotfile modules. Repeat `--profile` to combine them, or use `--profile all`.

| Profile | Included tools |
| --- | --- |
| `core-build` | Base development tools, Git, curl, wget, rsync, archives, jq, ShellCheck |
| `cpp` | GCC, Clang, CMake, Ninja, Meson, GDB, LLDB |
| `rust` | Rustup |
| `python` | Python, pip, uv |
| `web` | Node.js, npm, pnpm, Bun |
| `containers` | Docker, Docker Compose, Podman, Buildah |
| `wayland` | Portal, clipboard, screenshot, brightness, media, and DDC tooling |
| `media` | PipeWire, WirePlumber, FFmpeg, ImageMagick, yt-dlp |

## Package management

Package installation is opt-in through `--install-packages` or the interactive review. Kairo checks what is already installed and only requests packages required by the selected modules and profiles.

- Official packages are grouped into `sudo pacman -S --needed ...`.
- AUR packages use Paru by default or Yay with `--aur-helper yay`.
- AUR helpers run as the current user, never through `sudo`.
- A missing helper can be bootstrapped from its official AUR PKGBUILD.
- Kairo does not perform a surprise full-system upgrade.

When Fish and package installation are selected, Kairo installs Fisher when required and synchronizes the plugins declared in `.config/fish/fish_plugins`: `fzf.fish`, `autopair.fish`, and `replay.fish`. Generated functions and machine-specific `fish_variables` stay outside version control.

For Neovim, Kairo can bootstrap `lazy.nvim` and perform a headless LazyVim sync using the tracked `lazy-lock.json`. Without package installation, LazyVim performs its normal bootstrap when Neovim first starts.

Privileged work is requested only after review and before filesystem changes begin.

### Optional Chaotic-AUR support

[Chaotic-AUR](https://github.com/chaotic-aur) is treated as a separate trust decision:

```sh
./install.sh --dry-run --enable-chaotic-aur --profile web
./install.sh --enable-chaotic-aur --profile web
```

Kairo imports and locally signs the published key, installs the signed keyring and mirror list, backs up `/etc/pacman.conf`, and adds the repository idempotently. If the later transaction fails, the original Pacman configuration is restored.

## GPU drivers

With `--install-gpu-drivers`, Kairo inspects graphics controllers and proposes an Arch package set for review.

| Hardware | Proposed stack |
| --- | --- |
| AMD | Mesa and RADV Vulkan |
| Intel | Mesa, Intel Vulkan, and Intel media drivers |
| Modern NVIDIA | Open kernel modules, utilities, VA-API bridge, and matching installed-kernel headers |

Mixed Intel/AMD systems receive both applicable userspace stacks. Legacy or unclassified NVIDIA hardware produces a warning rather than a guess. Kairo does not generate an Xorg configuration or require Hyprland to be running.

## Rice branches

Each curated desktop palette lives on a `rice/*` Git branch and coordinates the relevant Kitty, Waybar, Hyprland, and wallpaper configuration.

| Family | Branches |
| --- | --- |
| Classic terminal | `rice/campbell`, `rice/vintage` |
| One Half | `rice/one-half-dark`, `rice/one-half-light` |
| Tango | `rice/tango-dark`, `rice/tango-light` |
| Catppuccin | `rice/catppuccin-latte`, `rice/catppuccin-frappe`, `rice/catppuccin-macchiato`, `rice/catppuccin-mocha` |
| Rosé Pine | `rice/rose-pine`, `rice/rose-pine-moon`, `rice/rose-pine-dawn` |

Switching rice is an ordinary Git workflow:

```sh
cd ~/kairo
git fetch origin
git switch rice/catppuccin-mocha

./install.sh --dry-run --only hypr --only kitty
./install.sh --only hypr --only kitty
```

`main` remains the stable development branch. Switching branches changes the configuration available to the installer; Git does not modify files already deployed under `~/.config`.

Kairo backs up replaced destinations unless `--no-backup` is explicitly supplied.

## Per-shell Starship

Kairo uses one Starship binary with a separate configuration for each shell:

```text
~/.config/starship/
├── bash.toml
├── fish.toml
├── nushell.toml
└── zsh.toml
```

`STARSHIP_CONFIG` selects the appropriate file. The installer manages the complete Starship directory rather than using a single root-level prompt configuration.

## Safety first

Kairo is designed to make workstation setup repeatable without turning configuration replacement into a gamble.

- Existing destinations are backed up under private, unique `~/.dotfiles-backup/YYYYMMDD-HHMMSS.xxxxxx/` directories.
- Replacement payloads are staged before activation.
- Failed operations restore replaced destinations and remove newly created partial targets.
- `/`, `$HOME`, the configuration root, traversal paths, symlink escapes, and destinations outside the home directory are rejected.
- `--dry-run` performs no writes, package changes, plugin installation, shell changes, or cache mutation.
- Repeated installations preserve unchanged payloads and avoid duplicate Git/SSH includes.
- Git identity, signing configuration, credentials, personal SSH material, `known_hosts`, and `authorized_keys` are not overwritten.
- `--no-backup` disables backup creation, not staging, destination validation, or rollback handling.

## Repository map

```text
kairo/
├── .config/
│   ├── bash/
│   ├── fish/
│   ├── nushell/
│   ├── oh-my-zsh/
│   ├── starship/
│   ├── wezterm/
│   ├── scripts/
│   │   ├── install-ui.sh
│   │   └── validate_repo.py
│   └── tests/
├── shell/                    # Local Quickshell prototype
├── site/
├── install.sh
├── VENDORED.md
└── LICENSE
```

## Website development

The website at [get-kairo.vercel.app](https://get-kairo.vercel.app) lives in [`site/`](site/) and uses Vite with Tailwind CSS v4.

```sh
cd site
bun install
bun run dev
bun run build
```

pnpm is also supported:

```sh
pnpm install
pnpm dev
pnpm build
```

## Validation

```sh
bash -n install.sh
bash -n .config/scripts/install-ui.sh
./install.sh --dry-run
./install.sh --dry-run --only starship
./install.sh --dry-run --only yazi --only broot --only starship
./install.sh --dry-run --only hypr --only kairo-shell
python3 .config/scripts/validate_repo.py
./.config/tests/test-install.sh
```

The Linux test suite covers normal and repeated installation, dry-run immutability, component selection, backup and no-backup modes, Git and SSH include deduplication, shell-specific Starship paths, rollback, remote bootstrap, non-interactive execution, terminal input handling, and Kairo Shell deployment, preservation, release verification, and rollback.

## License

Released under the terms of [LICENSE](LICENSE).
