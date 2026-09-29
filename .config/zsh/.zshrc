# Zsh rice: keep login/non-interactive shells quiet.
[[ -o interactive ]] || return

[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"
