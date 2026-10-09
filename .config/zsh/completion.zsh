# ==============================================================================
# ARCHNEMESIS // COMPLETION
# ==============================================================================

typeset -gaU fpath

for completions_dir in \
  "$ZSH_PLUGIN_DIR/zsh-completions/src" \
  "$ZSH_SYSTEM_PLUGIN_DIR/zsh-completions/src"
do
  [[ -d "$completions_dir" ]] \
    && fpath=("$completions_dir" $fpath)
done

zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completion"

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'no matches: %d'

[[ -n ${LS_COLORS:-} ]] \
  && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':fzf-tab:*' switch-group '<' '>'

if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' \
    fzf-preview 'eza --color=always --icons --group-directories-first -- "$realpath"'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'command ls -A -- "$realpath"'
fi
