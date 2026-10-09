# ==============================================================================
# ARCHNEMESIS // FUNCTIONS
# ==============================================================================

# ── Yazi cwd integration ───────────────────────────────────────────────────────

y() {
  (( $+commands[yazi] )) || {
    print 'yazi is not installed'
    return 127
  }

  local tmp cwd yazi_result

  tmp=$(mktemp -t yazi-cwd.XXXXXX) || return

  command yazi "$@" --cwd-file="$tmp"
  yazi_result=$?

  if [[ -s "$tmp" ]]; then
    IFS= read -r cwd < "$tmp"

    [[ -d "$cwd" && "$cwd" != "$PWD" ]] \
      && builtin cd -- "$cwd"
  fi

  command rm -f -- "$tmp"
  return "$yazi_result"
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

# Split editor arguments without evaluating shell code.
edit() {
  local -a editor_command
  editor_command=( ${(z)${VISUAL:-${EDITOR:-vi}}} )
  "${(@Q)editor_command}" "$@"
}

vf() {
  (( $+commands[fzf] )) || { print -u2 'fzf is not installed'; return 127; }
  local file
  local -a picker=(--read0 --print0)
  (( $+commands[bat] )) && picker+=(--preview 'bat --color=always --style=numbers --line-range=:250 -- {}')
  if (( $+commands[fd] )); then
    IFS= read -r -d '' file < <(command fd --type f --hidden --exclude .git --print0 | command fzf "${picker[@]}") || return 0
  else
    IFS= read -r -d '' file < <(command find . -name .git -prune -o -type f -print0 | command fzf "${picker[@]}") || return 0
  fi
  [[ -n $file ]] && edit -- "$file"
}

# ── FZF directory jump ─────────────────────────────────────────────────────────

cdf() {
  (( $+commands[fzf] )) || { print -u2 'fzf is not installed'; return 127; }
  local dir
  local -a picker=(--read0 --print0)
  (( $+commands[eza] )) && picker+=(--preview 'eza --tree --level=2 --icons --color=always -- {}')
  if (( $+commands[fd] )); then
    IFS= read -r -d '' dir < <(command fd --type d --hidden --exclude .git --print0 | command fzf "${picker[@]}") || return 0
  else
    IFS= read -r -d '' dir < <(command find . -name .git -prune -o -type d -print0 | command fzf "${picker[@]}") || return 0
  fi
  [[ -n $dir ]] && builtin cd -- "$dir"
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
  (( $+commands[git] )) || { print -u2 'git is not installed'; return 127; }
  local repo

  for repo in "$ZSH" "$ZSH_PLUGIN_DIR"/*(N/); do
    [[ -d "$repo/.git" ]] || continue

    print -P "%F{magenta}Updating ${repo:t}%f"

    git -C "$repo" pull --ff-only || return
  done
}
