# ==============================================================================
# ARCHNEMESIS // KEYBINDS
# ==============================================================================

bindkey -e
KEYTIMEOUT=15

# ── Navigation ─────────────────────────────────────────────────────────────────

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── History search ─────────────────────────────────────────────────────────────

if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi

# ── Autosuggestions ────────────────────────────────────────────────────────────

if (( $+widgets[autosuggest-accept] )); then
  bindkey '^ ' autosuggest-accept
fi
