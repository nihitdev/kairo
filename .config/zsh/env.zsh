# ==============================================================================
# ARCHNEMESIS // ENVIRONMENT
# ==============================================================================

# Optional distribution environment: opt in with a readable file path.
[[ -n ${ZSH_EXTRA_ENV_FILE:-} && -r $ZSH_EXTRA_ENV_FILE ]] \
  && source "$ZSH_EXTRA_ENV_FILE"

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

# Respect explicit choices; otherwise select an installed application.
if [[ -z ${EDITOR:-} ]]; then
  for candidate in nvim vim nano vi; do
    if (( $+commands[$candidate] )); then
      export EDITOR="$candidate"
      break
    fi
  done
fi
export VISUAL="${VISUAL:-${EDITOR:-vi}}"
export SUDO_EDITOR="${SUDO_EDITOR:-${EDITOR:-vi}}"
export GIT_EDITOR="${GIT_EDITOR:-${EDITOR:-vi}}"
export GIT_SEQUENCE_EDITOR="${GIT_SEQUENCE_EDITOR:-${EDITOR:-vi}}"
export SYSTEMD_EDITOR="${SYSTEMD_EDITOR:-${EDITOR:-vi}}"
export FCEDIT="${FCEDIT:-${EDITOR:-vi}}"
if [[ -z ${TERMINAL:-} ]]; then
  for candidate in kitty foot wezterm alacritty xterm; do
    if (( $+commands[$candidate] )); then
      export TERMINAL="$candidate"
      break
    fi
  done
fi
unset candidate

# ── Pager ──────────────────────────────────────────────────────────────────────

export PAGER="${PAGER:-less}"
export LESS="${LESS:--R -F -X}"

# ── Zsh ────────────────────────────────────────────────────────────────────────

export ZSH="${ZSH:-$XDG_DATA_HOME/zsh/oh-my-zsh}"
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"
export ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$XDG_DATA_HOME/zsh/plugins}"
export ZSH_SYSTEM_PLUGIN_DIR="${ZSH_SYSTEM_PLUGIN_DIR:-/usr/share/zsh/plugins}"
export ZSH_COMPDUMP="${ZSH_COMPDUMP:-$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION}"

mkdir -p "$ZSH_CACHE_DIR" "$XDG_STATE_HOME/zsh"

# ── Starship ───────────────────────────────────────────────────────────────────

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship/zsh.toml}"

# ── FZF ────────────────────────────────────────────────────────────────────────

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-fd --type f --hidden --exclude .git}"
  export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-fd --type d --hidden --exclude .git}"
else
  export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-find . -name .git -prune -o -type f -print}"
  export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-find . -name .git -prune -o -type d -print}"
fi
export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND:-$FZF_DEFAULT_COMMAND}"
if (( $+commands[bat] )) && [[ -z ${FZF_CTRL_T_OPTS:-} ]]; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 -- {}'"
fi
if (( $+commands[eza] )) && [[ -z ${FZF_ALT_C_OPTS:-} ]]; then
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons -- {}'"
fi

if [[ -z ${FZF_DEFAULT_OPTS:-} ]]; then
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

fi
