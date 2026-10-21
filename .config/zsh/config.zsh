# ==============================================================================
# ARCHNEMESIS // ZSH
# ==============================================================================

typeset -g ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

for module in \
  env \
  options \
  completion \
  plugins \
  keybinds \
  aliases \
  functions \
  integrations
do
  source "$ZSH_CONFIG_DIR/$module.zsh"
done

# Must remain last so widget wrapping works correctly.
source "$ZSH_CONFIG_DIR/highlighting.zsh"

# Shared Prism terminal palette.
PRISM_INIT="${XDG_CONFIG_HOME:-$HOME/.config}/prism/init.sh"
if [[ -r "$PRISM_INIT" ]]; then
  source "$PRISM_INIT"
fi
