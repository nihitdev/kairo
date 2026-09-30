# ==============================================================================
# ARCHNEMESIS // ENVIRONMENT
# ==============================================================================

[[ -r /usr/share/omarchy/default/bash/envs ]] \
  && source /usr/share/omarchy/default/bash/envs

# ── XDG ────────────────────────────────────────────────────────────────────────

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ── PATH ───────────────────────────────────────────────────────────────────────

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  $path
)

# ── Default applications ───────────────────────────────────────────────────────

export TERMINAL="kitty"

export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
export GIT_EDITOR="nvim"
export GIT_SEQUENCE_EDITOR="nvim"
export SYSTEMD_EDITOR="nvim"
export FCEDIT="nvim"

# ── Pager ──────────────────────────────────────────────────────────────────────

export PAGER="less"
export LESS="-R -F -X"

# ── Zsh ────────────────────────────────────────────────────────────────────────

export ZSH="${ZSH:-$XDG_DATA_HOME/zsh/oh-my-zsh}"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

mkdir -p "$ZSH_CACHE_DIR" "$XDG_STATE_HOME/zsh"

# ── Starship ───────────────────────────────────────────────────────────────────

export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/zsh.toml"

# ── FZF ────────────────────────────────────────────────────────────────────────

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:200 -- {}'
"

export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always --icons -- {}'
"

export FZF_DEFAULT_OPTS="
  --height=45%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='> '
  --pointer='▌'
  --marker='✓'
  --color=bg+:#313244
  --color=fg:#cdd6f4
  --color=fg+:#cdd6f4
  --color=hl:#f5c2e7
  --color=hl+:#f5c2e7
  --color=border:#cba6f7
  --color=prompt:#cba6f7
  --color=pointer:#94e2d5
  --color=marker:#a6e3a1
  --color=spinner:#f5c2e7
  --color=header:#89b4fa
"
