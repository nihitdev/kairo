# Zsh rice: keep login/non-interactive shells quiet.
[[ -o interactive ]] || return

[[ -r "$HOME/.config/zsh/config.zsh" ]] && source "$HOME/.config/zsh/config.zsh"
