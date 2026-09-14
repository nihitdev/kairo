# Environment and tools from Omarchy, compatible with Zsh.
[[ -r /usr/share/omarchy/default/bash/envs ]] && source /usr/share/omarchy/default/bash/envs

export ZSH="${ZSH:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/oh-my-zsh}"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
export STARSHIP_CONFIG="$HOME/.config/starship/zsh.toml"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 -- {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always -- {}'"
export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline --prompt='>' --pointer='>' --marker='+' --color=bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4,hl:#f5c2e7,hl+:#f5c2e7,border:#cba6f7,prompt:#cba6f7,pointer:#94e2d5,marker:#a6e3a1,spinner:#f5c2e7,header:#89b4fa"

mkdir -p "$ZSH_CACHE_DIR" "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"

ZSH_THEME=""
zstyle ':omz:update' mode disabled
DISABLE_AUTO_TITLE=true
plugins=(git sudo extract copypath copyfile dirhistory colored-man-pages command-not-found history jsontools urltools)

typeset -gaU fpath path
for completions_dir in \
  "$HOME/.local/share/zsh/plugins/zsh-completions/src" \
  /usr/share/zsh/plugins/zsh-completions/src; do
  [[ -d "$completions_dir" ]] && fpath=("$completions_dir" $fpath)
done

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "$ZSH_COMPDUMP"
fi

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS
unsetopt CORRECT CORRECT_ALL
bindkey -e
KEYTIMEOUT=15

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu no
[[ -n ${LS_COLORS:-} ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons --group-directories-first -- "$realpath"'

__zsh_source_first() {
  local plugin
  for plugin in "$@"; do
    [[ -r "$plugin" ]] || continue
    source "$plugin"
    return 0
  done
  return 1
}

if (( $+commands[fzf] )) && [[ -t 1 ]]; then
  __zsh_source_first <(fzf --zsh)
fi

__zsh_source_first \
  "$HOME/.local/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" \
  /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
__zsh_source_first \
  "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

if __zsh_source_first \
  "$HOME/.local/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi

(( $+widgets[autosuggest-accept] )) && bindkey '^ ' autosuggest-accept
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -lah --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
fi
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ports='ss -tulpn'
alias lg='lazygit'
alias top='btop'
alias ff='fastfetch'
alias preview='bat --style=numbers'
(( $+commands[duf] )) && alias disks='duf'
(( $+commands[dust] )) && alias usage='dust'
(( $+commands[delta] )) && alias gdiff='git -c core.pager=delta diff'
alias reload='exec zsh'

y() {
  (( $+commands[yazi] )) || { print 'yazi is not installed yet'; return 127; }
  local tmp cwd
  tmp=$(mktemp -t yazi-cwd.XXXXXX) || return
  yazi "$@" --cwd-file="$tmp"
  if [[ -s "$tmp" ]]; then
    IFS= read -r cwd < "$tmp"
    [[ -d "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

mkcd() { [[ $# == 1 ]] || { print 'Usage: mkcd DIRECTORY'; return 2; }; mkdir -p -- "$1" && cd -- "$1"; }
rice-help() { cat "$HOME/.config/zsh/README.md"; }
rice-update() {
  local repo
  for repo in "$ZSH" "$HOME"/.local/share/zsh/plugins/*; do
    [[ -d "$repo/.git" ]] || continue
    print -P "%F{magenta}Updating ${repo:t}%f"
    git -C "$repo" pull --ff-only || return
  done
}

(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && [[ -t 1 ]] && eval "$(starship init zsh)"

# Load highlighting after other widgets.
__zsh_source_first \
  "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

unfunction __zsh_source_first
