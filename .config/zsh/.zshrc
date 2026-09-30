# ==============================================================================
# ARCHNEMESIS // ZSH ENTRYPOINT
# ==============================================================================

[[ -o interactive ]] || return

source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"
