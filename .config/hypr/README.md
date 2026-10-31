# ARCHNEMESIS desktop

Rosé Pine desktop tuned for the 1366×768 laptop panel. The existing Dwindle/Scrolling/Master cycle, wallpapers, cat and skull animations remain available.

Press **Super+/** or click the skull in Waybar for the searchable shortcut reference. New window controls include Super+F (fullscreen), Super+Shift+F (maximize), Super+Shift+Space (floating), Super+Shift+Arrows (move), and Super+Ctrl+Arrows (resize). Ctrl+Print captures the active window rectangle; screenshots are saved in ~/Pictures/Screenshots and copied as PNG.

**Super+T** toggles a centered Kitty scratchpad on the special workspace. It uses Kitty-Smooth when installed and regular Kitty otherwise.

Super+Shift+R validates the Lua configuration before reloading. Super+L switches and persists the layout, restoring the previous file if validation fails. Hyprland also automatically reloads configuration edits.

Waybar uses native network and Bluetooth status modules. Click either for the existing terminal settings tools. Media controls follow the available MPRIS player. Click notifications to open the panel, right-click for Do Not Disturb, and middle-click to clear notifications. Critical notifications remain until dismissed.

Files: config/*.lua for compositor settings, ../waybar/{config.jsonc,style.css} for the bar, ../rofi/style-1.rasi for the launcher, and ../quickshell/hyprland-notifications/ for notifications. Utility terminals float at 70% of the monitor size.

## Restore a previous desktop

The installer prints the backup directory after replacing existing configuration.
Restore the desired files from that backup into `~/.config`, then run
`Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` before `hyprctl reload`.
Restart `waybar.service` after restoring Waybar files. Notifications use the
Quickshell configuration at `~/.config/quickshell/hyprland-notifications`.
Machine-specific backup paths and wallpaper links are not distributed.

## Layouts and motion

Super+L or the Waybar layout button cycles Dwindle → Scrolling → Master → Dwindle. Scrolling is a native Hyprland layout; all three layouts run in Hyprland. Master gives the left window 60% of the screen and stacks other windows on the right; new windows join the stack. The selected layout persists across restarts.

Animations use a subtle 99% opening/closing scale, faster closing/fades, and smooth workspace slides. Desktop sizing and transparency are independent of these settings.
