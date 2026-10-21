# Prism engine

Run `prism theme list`, `prism theme preview NAME`, `prism theme switch NAME`,
`prism theme back` or `prism theme current`.

Palettes: `arch-blue`, `catppuccin`, `rose-pine`. Edit `prism.py` to customize them.
Colors are shared across Starship, Fastfetch, Kitty, FZF and shell highlighting.
Switching refreshes the invoking shell's colors and reloads your Kitty processes.
Use `prism --no-reload theme switch NAME` to skip Kitty reloads.

Files are backed up under `$XDG_CONFIG_HOME/config-backups/prism-switch-*`.
`theme back` switches to the previous palette; it does not restore file backups.
Desktop and editor themes are not managed. Fish also provides `kairo` as a
compatibility alias for `prism`.
