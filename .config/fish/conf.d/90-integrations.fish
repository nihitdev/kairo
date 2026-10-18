# ==============================================================================
# ARCHNEMESIS // INTEGRATIONS
# ==============================================================================

# conf.d files also run in non-interactive shells.
status is-interactive; or return

# ── mise ───────────────────────────────────────────────────────────────────────

if type -q mise
    mise activate fish | source
end

# ── zoxide ─────────────────────────────────────────────────────────────────────

if type -q zoxide
    zoxide init fish | source
end

# ── direnv ─────────────────────────────────────────────────────────────────────

if type -q direnv
    direnv hook fish | source
end

# ── Starship ───────────────────────────────────────────────────────────────────

if type -q starship
    starship init fish | source
end
