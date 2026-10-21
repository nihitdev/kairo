# ─────────────────────────────────────────────────────────────────────────────
# Bash
# Arch Linux • Starship • Modern CLI tools
# ─────────────────────────────────────────────────────────────────────────────

case $- in
    *i*) ;;
    *) return ;;
esac

export EDITOR=nvim
export VISUAL=nvim

if [[ -d $HOME/.local/bin ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if command -v starship >/dev/null 2>&1; then
    export STARSHIP_CONFIG="$HOME/.config/starship/bash.toml"
    eval "$(starship init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

# Prism keeps terminal-facing palettes in sync; leave Bash usable without it.
PRISM_INIT="${XDG_CONFIG_HOME:-$HOME/.config}/prism/init.sh"
if [[ -r $PRISM_INIT ]]; then
    source "$PRISM_INIT"
fi
