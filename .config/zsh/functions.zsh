# ==============================================================================
# ARCHNEMESIS // FUNCTIONS
# ==============================================================================

# ── Yazi cwd integration ───────────────────────────────────────────────────────

y() {
  (( $+commands[yazi] )) || {
    print 'yazi is not installed'
    return 127
  }

  local tmp cwd

  tmp=$(mktemp -t yazi-cwd.XXXXXX) || return

  yazi "$@" --cwd-file="$tmp"

  if [[ -s "$tmp" ]]; then
    IFS= read -r cwd < "$tmp"

    [[ -d "$cwd" && "$cwd" != "$PWD" ]] \
      && builtin cd -- "$cwd"
  fi

  rm -f -- "$tmp"
}

# ── Create + enter directory ───────────────────────────────────────────────────

mkcd() {
  [[ $# == 1 ]] || {
    print 'Usage: mkcd DIRECTORY'
    return 2
  }

  mkdir -p -- "$1" && builtin cd -- "$1"
}

# ── FZF file editor ────────────────────────────────────────────────────────────

vf() {
  (( $+commands[fzf] )) || {
    print 'fzf is not installed'
    return 127
  }

  local file

  if (( $+commands[fd] )); then
    file=$(
      fd --type f --hidden --exclude .git |
        fzf --preview 'bat --color=always --style=numbers --line-range=:250 -- {}'
    )
  else
    file=$(
      find . -type f |
        fzf
    )
  fi

  [[ -n "$file" ]] && nvim -- "$file"
}

# ── FZF directory jump ─────────────────────────────────────────────────────────

cdf() {
  (( $+commands[fzf] )) || {
    print 'fzf is not installed'
    return 127
  }

  local dir

  if (( $+commands[fd] )); then
    dir=$(
      fd --type d --hidden --exclude .git |
        fzf --preview 'eza --tree --level=2 --icons --color=always -- {}'
    )
  else
    dir=$(
      find . -type d |
        fzf
    )
  fi

  [[ -n "$dir" ]] && builtin cd -- "$dir"
}

# ── Rice help ──────────────────────────────────────────────────────────────────

rice-help() {
  local readme="$XDG_CONFIG_HOME/zsh/README.md"

  if [[ -r "$readme" ]]; then
    bat --style=plain "$readme" 2>/dev/null || command cat "$readme"
  else
    print 'No Zsh README found.'
  fi
}

# ── Update shell plugins ───────────────────────────────────────────────────────

rice-update() {
  local repo

  for repo in "$ZSH" "$HOME"/.local/share/zsh/plugins/*; do
    [[ -d "$repo/.git" ]] || continue

    print -P "%F{magenta}Updating ${repo:t}%f"

    git -C "$repo" pull --ff-only || return
  done
}
