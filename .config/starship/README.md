# Starship

Custom Starship prompt configurations for multiple shells.

## Structure

```text
~/.config/starship/
├── bash.toml
├── fish.toml
├── nushell.toml
└── zsh.toml
```

Each shell uses its own Starship configuration while sharing the same Starship binary.

## Shell Configuration

### Bash

```bash
export STARSHIP_CONFIG="$HOME/.config/starship/bash.toml"
eval "$(starship init bash)"
```

### Fish

```fish
set -gx STARSHIP_CONFIG "$HOME/.config/starship/fish.toml"
starship init fish | source
```

### Nushell

```nu
$env.STARSHIP_CONFIG = ($nu.home-dir | path join ".config" "starship" "nushell.toml")
```

### Zsh

```zsh
export STARSHIP_CONFIG="$HOME/.config/starship/zsh.toml"
eval "$(starship init zsh)"
```

## Installation

On Arch Linux:

```bash
sudo pacman -S starship
```

## Requirements

* Starship
* Nerd Font for icons and symbols
