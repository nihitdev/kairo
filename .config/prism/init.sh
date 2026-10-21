# Shared by interactive Bash and Zsh.
. "${XDG_CONFIG_HOME:-$HOME/.config}/prism/theme.sh"
prism() {
    command prism "$@"
    local result=$?
    if [ "$result" -eq 0 ] && [ "${1:-}" = theme ]; then
        case "${2:-}" in
            switch|back) . "${XDG_CONFIG_HOME:-$HOME/.config}/prism/theme.sh" ;;
        esac
    fi
    return "$result"
}
