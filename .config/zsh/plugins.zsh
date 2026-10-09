# ==============================================================================
# ARCHNEMESIS // PLUGINS
# ==============================================================================

_source_first() {
  local plugin

  for plugin in "$@"; do
    [[ -r "$plugin" ]] || continue

    source "$plugin"
    return 0
  done

  return 1
}

# ── Oh My Zsh ──────────────────────────────────────────────────────────────────

ZSH_THEME=""

zstyle ':omz:update' mode disabled
DISABLE_AUTO_TITLE=true

plugins=(
  git
  sudo
  extract
  copypath
  copyfile
  dirhistory
  colored-man-pages
  command-not-found
  history
  jsontools
  urltools
)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "$ZSH_COMPDUMP"
fi


# ── FZF ────────────────────────────────────────────────────────────────────────

if (( $+commands[fzf] )) && [[ -t 1 ]]; then
  eval "$(fzf --zsh 2>/dev/null)" 2>/dev/null
fi

# ── fzf-tab ────────────────────────────────────────────────────────────────────

_source_first \
  "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" \
  "$ZSH_SYSTEM_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"

# ── Autosuggestions ────────────────────────────────────────────────────────────

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'

_source_first \
  "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$ZSH_SYSTEM_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ── History substring search ───────────────────────────────────────────────────

_source_first \
  "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$ZSH_SYSTEM_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"

# ── Auto pairs ─────────────────────────────────────────────────────────────────

_source_first \
  "$ZSH_PLUGIN_DIR/zsh-autopair/autopair.zsh" \
  "$ZSH_SYSTEM_PLUGIN_DIR/zsh-autopair/autopair.zsh"

# ── Forgit ─────────────────────────────────────────────────────────────────────

# Keep ARCHNEMESIS aliases authoritative. Forgit is used through its own
# commands/widgets instead of replacing our existing Git shortcuts.
export FORGIT_NO_ALIASES=1

_source_first \
  "$ZSH_PLUGIN_DIR/forgit/forgit.plugin.zsh" \
  "$ZSH_SYSTEM_PLUGIN_DIR/forgit/forgit.plugin.zsh"

