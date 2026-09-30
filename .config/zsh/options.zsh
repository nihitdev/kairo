# ==============================================================================
# ARCHNEMESIS // OPTIONS
# ==============================================================================

# ── History ────────────────────────────────────────────────────────────────────

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# ── Navigation ─────────────────────────────────────────────────────────────────

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# ── Completion ─────────────────────────────────────────────────────────────────

setopt AUTO_LIST
setopt AUTO_MENU
setopt AUTO_PARAM_SLASH
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# ── Shell behavior ─────────────────────────────────────────────────────────────

setopt INTERACTIVE_COMMENTS
setopt EXTENDED_GLOB
setopt NO_BEEP
setopt PROMPT_SUBST

unsetopt CORRECT
unsetopt CORRECT_ALL
