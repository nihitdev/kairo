<div align="center">

# Kairo

### Arch, composed.

A safe, interactive installer for an Arch Linux, Hyprland, and CLI-first workstation.

[![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Website](https://img.shields.io/badge/Website-get--kairo.vercel.app-cba6f7)](https://get-kairo.vercel.app)
[![Shell](https://img.shields.io/badge/Installer-Bash-a6e3a1?logo=gnubash&logoColor=11111b)](install.sh)
[![License](https://img.shields.io/github/license/nihitdev/kairo)](LICENSE)

[Website](https://get-kairo.vercel.app) · [Quick start](#quick-start) · [Modules](#included-configurations) · [Safety](#safety-first)

</div>

Kairo turns a fresh Arch installation into a focused development environment without treating your home directory like a blank canvas. It combines curated dotfiles, optional package installation, developer toolchains, GPU detection, and a dependency-free terminal UI with transactional replacement and rollback.

## Highlights

- Full-screen interactive installer built with Bash and standard terminal sequences
- Arch-first package management with `pacman`, plus optional Paru or Yay support
- Selectable dotfile modules and independent developer toolchain profiles
- Intel, AMD, and NVIDIA GPU detection with reviewed driver proposals
- Private backups, staged replacements, path validation, and transaction rollback
- Deterministic plain output for CI, redirected output, and automation
- Separate Starship configuration for Bash, Fish, Nushell, and Zsh
- Fish login-shell setup after a successful interactive installation
- Switchable rice branches with coordinated Hyprland, Waybar, Kitty, and wallpaper colors

## Quick start

### 1. Curl

```sh
curl -fsSL https://raw.githubusercontent.com/nihitdev/kairo/main/install.sh | bash
```

### 2. Wget

```sh
wget -qO- https://raw.githubusercontent.com/nihitdev/kairo/main/install.sh | bash
```

Both remote entry points request sudo access, clone Kairo to `~/kairo`, enter the checkout, and launch the full interactive installer. An existing clean Kairo checkout is updated with a fast-forward pull; unrelated or modified directories are never overwritten. CI and redirected/non-terminal sessions remain plain and deterministic.

### 3. Clone

```sh
git clone https://github.com/nihitdev/kairo.git
cd kairo
./install.sh
```

Cloning provides the complete interactive TUI. Start with a zero-write preview if you want to inspect every action first:

```sh
./install.sh --dry-run
```

## Installer experience

Running `./install.sh` in a terminal opens a guided flow:

```text
Welcome → Detect → Dependencies → Modules → Review
        → Backup → Packages → Dotfiles → Configure → Validate → Complete
```

Kairo shows the detected distribution, architecture, shell, display session, package tools, service manager, and configuration root. Before changing anything, the review screen lists selected modules, missing packages, replacement targets, and backup behavior.

### Controls

| Key | Action |
| --- | --- |
| `↑` / `↓` or `J` / `K` | Move through choices |
| `Space` | Toggle the focused item |
| `A` | Select all |
| `N` | Select none |
| `Enter` | Continue |
| `Q` or `Esc` | Cancel safely |

## Useful commands

```sh
# Preview one module
./install.sh --dry-run --only starship

# Install several modules
./install.sh --only yazi --only broot --only starship

# Install every supported dotfile module
./install.sh --only all

# Install missing packages for the selected modules
./install.sh --install-packages --only nvim --only yazi

# Add developer toolchains
./install.sh --install-packages --profile core-build --profile rust --profile web

# Select Yay instead of the default Paru helper
./install.sh --install-packages --aur-helper yay

# Review and install detected GPU drivers
./install.sh --install-packages --install-gpu-drivers

# Disable backup creation explicitly
./install.sh --no-backup --only starship
```

Run `./install.sh --help` for the authoritative option and component list.

## Rice branches

Kairo ships each complete desktop palette as a Git branch. Switch the checkout,
then apply its Hyprland, Waybar, Kitty, and wallpaper configuration through the
same transactional installer:

```sh
cd ~/kairo
git fetch origin
git switch rice/catppuccin-mocha
./install.sh --only hypr --only kitty
```

Preview the replacement first with `--dry-run`. To change rice later, return to
a clean checkout, switch to another `rice/*` branch, and run the same install
command. Kairo backs up replaced configuration unless `--no-backup` is given.

Available branches:

| Family | Branches |
| --- | --- |
| Classic terminal | `rice/campbell`, `rice/vintage` |
| One Half | `rice/one-half-dark`, `rice/one-half-light` |
| Tango | `rice/tango-dark`, `rice/tango-light` |
| Catppuccin | `rice/catppuccin-latte`, `rice/catppuccin-frappe`, `rice/catppuccin-macchiato`, `rice/catppuccin-mocha` |
| Rosé Pine | `rice/rose-pine`, `rice/rose-pine-moon`, `rice/rose-pine-dawn` |

`main` remains the stable development branch. Rice branches contain distinct
palette files, so changing branches changes the configuration that the installer
deploys; Git itself does not rewrite the already-installed files in `~/.config`.

## Included configurations

| Area | Modules |
| --- | --- |
| Shells | [Bash](.config/bash/), [Fish](.config/fish/), [Nushell](.config/nushell/), [Zsh + Oh My Zsh](.config/oh-my-zsh/) |
| Prompt and history | [Starship](.config/starship/), [Atuin](.config/atuin/), [Oh My Posh](.config/oh-my-posh/) |
| CLI workflow | [Bat](.config/bat/), [Broot](.config/broot/), [Yazi](.config/yazi/), [LazyGit](.config/lazygit/), [Fastfetch](.config/fastfetch/), [Cava](.config/cava/) |
| Development | [Git](.config/git/), [Neovim](.config/nvim/), [SSH](.config/ssh/) |
| Desktop | [WezTerm](.config/wezterm/), [Kitty](.config/kitty/), [Hyprland](.config/hypr/), [Waybar](.config/waybar/) |

Hyprland is opt-in because replacing a compositor configuration can disrupt an active session. Preview it before installation:

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

## Developer toolchains

Profiles install workstation packages independently from dotfile modules. Repeat `--profile` to combine them or use `--profile all`.

| Profile | Included tools |
| --- | --- |
| `core-build` | Base development tools, Git, curl, wget, rsync, archives, jq, ShellCheck |
| `cpp` | GCC, Clang, CMake, Ninja, Meson, GDB, LLDB |
| `rust` | Rustup |
| `python` | Python, pip, uv |
| `web` | Node.js, npm, pnpm, Bun |
| `containers` | Docker, Docker Compose, Podman, Buildah |
| `wayland` | Portal, clipboard, screenshots, brightness, media, and DDC tools |
| `media` | PipeWire, WirePlumber, FFmpeg, ImageMagick, yt-dlp |

## Package management

Package installation is always opt-in through `--install-packages` or the interactive review. Kairo checks what is already present and installs only packages needed by the selected modules and profiles.

- Official packages are grouped into `sudo pacman -S --needed ...`.
- AUR packages use Paru by default or Yay with `--aur-helper yay`.
- AUR helpers are never run through `sudo` or as root.
- A missing helper is bootstrapped from its official AUR PKGBUILD as the current user.
- Kairo never performs a surprise full-system upgrade.

When Fish is selected with `--install-packages`, Kairo installs Fisher when needed and synchronizes the plugins declared in `.config/fish/fish_plugins`: `fzf.fish`, `autopair.fish`, and `replay.fish`. Fisher-generated functions and machine-specific `fish_variables` remain outside version control.

When Neovim is selected with `--install-packages`, Kairo bootstraps `lazy.nvim` and performs a headless LazyVim sync using the tracked `lazy-lock.json`. Without package installation, LazyVim performs its normal bootstrap the first time Neovim opens.

When privileged work is selected, interactive mode requests and validates sudo access after review and before filesystem changes begin.

### Chaotic-AUR

[Chaotic-AUR](https://github.com/chaotic-aur) is an optional third-party repository and a separate trust decision:

```sh
./install.sh --dry-run --enable-chaotic-aur --profile web
./install.sh --enable-chaotic-aur --profile web
```

Kairo imports and locally signs the published key, installs the signed keyring and mirror list, backs up `/etc/pacman.conf`, and adds the repository idempotently. If the later transaction fails, the original Pacman configuration is restored.

## GPU drivers

With `--install-gpu-drivers`, Kairo inspects graphics controllers and proposes an Arch package set for review:

| Detected hardware | Proposed stack |
| --- | --- |
| AMD | Mesa and RADV Vulkan |
| Intel | Mesa, Intel Vulkan, and Intel media drivers |
| Modern NVIDIA | Open kernel modules, utilities, VA-API bridge, and matching installed-kernel headers |

Mixed Intel/AMD systems receive both applicable userspace stacks. Unclassified or legacy NVIDIA hardware produces a warning instead of guessing. Kairo does not generate an Xorg configuration or require Hyprland to be running.

## Per-shell Starship

One Starship binary is shared across all shells, while `STARSHIP_CONFIG` selects a shell-specific configuration:

```text
~/.config/starship/
├── bash.toml       # Bash
├── fish.toml       # Fish
├── nushell.toml    # Nushell
└── zsh.toml        # Zsh
```

The installer manages the complete directory; Kairo does not use a single prompt file at the configuration root.

## Rice branches

Kairo publishes one Git branch per curated rice. Each branch includes a matching Kitty palette, Waybar accents, and Hyprland border colors:

```text
rice/campbell             rice/vintage
rice/one-half-dark        rice/one-half-light
rice/tango-dark           rice/tango-light
rice/catppuccin-latte     rice/catppuccin-frappe
rice/catppuccin-macchiato rice/catppuccin-mocha
rice/rose-pine            rice/rose-pine-moon
rice/rose-pine-dawn
```

Switching a rice is intentionally an ordinary Git workflow. From a clean checkout, select a branch and reinstall the affected components:

```sh
git fetch origin
git switch rice/catppuccin-mocha
./install.sh --only kitty --only hypr
```

Waybar is included in the repository at `.config/waybar`; copy it to `~/.config/waybar` (or use your usual dotfile deployment step) after switching. Return to the default configuration with `git switch main`. The installer backs up replaced destinations, so switching back is reversible.

## Safety first

Kairo preserves the existing installer’s transactional design:

- Existing destinations are backed up under private, unique `~/.dotfiles-backup/YYYYMMDD-HHMMSS.xxxxxx/` directories.
- Replacement payloads are staged before activation.
- A failed operation restores replaced destinations and removes newly created partial targets.
- Destinations outside the home directory, traversal paths, symlink escapes, `/`, `$HOME`, and the configuration root itself are rejected.
- `--dry-run` performs no writes, package changes, plugin installation, shell changes, or cache mutation.
- Repeated installation is safe: unchanged payloads are retained and Git/SSH includes are not duplicated.
- Git identity, signing, credentials, personal SSH material, `known_hosts`, and `authorized_keys` are not overwritten.

`--no-backup` disables backup creation but does not disable staging, destination safety, or rollback handling.

## Repository map

```text
dotfiles/
├── .config/
│   ├── bash/                 # Managed Bash configuration
│   ├── fish/                 # Fish configuration and integrations
│   ├── nushell/              # Nushell configuration and startup files
│   ├── oh-my-zsh/            # Zsh + Oh My Zsh configuration
│   ├── starship/             # Four shell-specific prompt configs
│   ├── wezterm/              # Modular WezTerm configuration
│   ├── scripts/
│   │   ├── install-ui.sh     # Dependency-free terminal UI
│   │   └── validate_repo.py  # Repository validation
│   └── tests/                # Linux installer tests
├── site/                     # Vite + Tailwind CSS website
├── install.sh                # Main installer and remote entry point
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
python3 .config/scripts/validate_repo.py
./.config/tests/test-install.sh
```

The Linux test suite covers normal and repeated installation, dry-run immutability, component selection, backup and no-backup modes, Git and SSH include deduplication, shell-specific Starship paths, rollback, remote bootstrap, non-interactive execution, and terminal input handling.

## License

Released under the terms in [LICENSE](LICENSE).
