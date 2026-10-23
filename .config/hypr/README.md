# ARCHNEMESIS desktop

Hyprland 0.56+ Lua configuration with Dwindle, Scrolling (Niri-style columns), and Master layouts. Press **Super+L** or click the Waybar layout indicator to cycle; the selection persists across restarts. Master puts the main window on the left at 60% width and stacks other windows on the right.

Press **Super+/** for the searchable [shortcut reference](shortcuts.txt). **Super+F** toggles fullscreen; **Super+Shift+F** maximizes; **Super+Shift+Space** toggles floating. Super+Shift+Arrows moves windows, and Super+Ctrl+Arrows resizes them. **Super+F5/F6** adjusts brightness. **Ctrl+Print** captures the focused window. **Super+Shift+R** validates and reloads the compositor config. Hyprland also automatically reloads edits to its config files.

The theme uses a transparent 32px Waybar with wallpaper-derived colors, a compact 400px Rofi launcher, and a Quickshell notification center with toasts, session history, DND, and clear-all. Waybar runs as a systemd user service tied to `graphical-session.target` and restarts after failures. Workspaces appear as dots only while occupied or currently viewed. Both wallpaper pickers update the bar palette automatically; login restores it.

## Files

- `config/*.lua`: compositor behavior, animation timings, and keybindings.
- `config/appearance.lua`: theme and layout settings.
- `scripts/`: layout switching, screenshot, lock, wallpaper, and desktop helpers.
- `../waybar/`, `../rofi/`, `../quickshell/hyprland-notifications/`, `../hyprlock/`: companion desktop configurations.

Screenshots go to `~/Pictures/Screenshots` and are copied as PNG. **Ctrl+Print** captures the active window rectangle. Utility terminals float at 70% of the display size.

Waybar provides live network/Bluetooth status. Click its notification icon or press **Super+Shift+N** to open the panel, right-click the icon for Do Not Disturb, or middle-click to clear history. Critical notifications remain until dismissed. SwayNC remains an explicit alternative; the installer disables its competing service when selected.

## Install

From the repository root, preview with `./install.sh --dry-run --only hypr --only rofi`, then install with `./install.sh --only hypr --only rofi --install-packages`. The explicit Rofi selection replaces an existing launcher theme; Hyprland alone seeds Rofi only when absent. Existing configs are backed up by default. The 25 bundled images (18 Catppuccin Space & Cosmic images plus seven personal wallpapers) are seeded directly into `~/Pictures/Wallpapers`, with no nested folders; fresh installs select `snow-pine-forest.png`. Existing wallpaper selections and personal files are preserved. Machine-specific links and generated lockscreen configs are not distributed.

Use the main repository README for installation and rollback details. The installer does not restart your session.
