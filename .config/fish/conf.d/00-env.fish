# ==============================================================================
# ARCHNEMESIS // ENVIRONMENT
# ==============================================================================

# ── XDG ────────────────────────────────────────────────────────────────────────

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_STATE_HOME "$HOME/.local/state"

# ── PATH ───────────────────────────────────────────────────────────────────────

fish_add_path --global --move "$HOME/.local/bin"

# ── Default applications ───────────────────────────────────────────────────────

set -gx TERMINAL kitty

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx GIT_EDITOR nvim
set -gx GIT_SEQUENCE_EDITOR nvim
set -gx SYSTEMD_EDITOR nvim
set -gx FCEDIT nvim

# ── Pager ──────────────────────────────────────────────────────────────────────

set -gx PAGER less
set -gx LESS "-R -F -X"

# ── Starship ───────────────────────────────────────────────────────────────────

set -gx STARSHIP_CONFIG "$HOME/.config/starship/fish.toml"

# Fall back to the existing Zsh Starship config if Fish does not have its own.
if not test -f "$STARSHIP_CONFIG"
    set -gx STARSHIP_CONFIG "$HOME/.config/starship/zsh.toml"
end

# ── FZF ────────────────────────────────────────────────────────────────────────

set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git"

set -gx FZF_DEFAULT_OPTS \
    "--height=45%" \
    "--layout=reverse" \
    "--border=rounded" \
    "--info=inline" \
    "--prompt=> " \
    "--pointer=▌" \
    "--marker=✓" \
    "--color=bg+:#313244" \
    "--color=fg:#cdd6f4" \
    "--color=fg+:#cdd6f4" \
    "--color=hl:#f5c2e7" \
    "--color=hl+:#f5c2e7" \
    "--color=border:#cba6f7" \
    "--color=prompt:#cba6f7" \
    "--color=pointer:#94e2d5" \
    "--color=marker:#a6e3a1" \
    "--color=spinner:#f5c2e7" \
    "--color=header:#89b4fa"
