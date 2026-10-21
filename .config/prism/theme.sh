export FZF_DEFAULT_OPTS="$(printf '%s' "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--color=[^ ]+//g') --color=bg:#191724,bg+:#26233a,fg:#e0def4,fg+:#e0def4,hl:#9ccfd8,hl+:#9ccfd8,border:#ebbcba,prompt:#ebbcba,pointer:#9ccfd8,marker:#9ccfd8,spinner:#9ccfd8,header:#31748f"
if [ -n "${ZSH_VERSION:-}" ]; then
  typeset -gA ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=#ebbcba'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ebbcba'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#ebbcba'
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c4a7e7'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ccfd8'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ccfd8'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#908caa'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#eb6f92'
fi
