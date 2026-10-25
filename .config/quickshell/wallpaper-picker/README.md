# Standalone wallpaper carousel

Open with Super + Alt + Space (press again to close).
Arrow keys / mouse wheel browse; click a card to select, click again or Enter to apply. Escape closes.
Search filters local filenames. Colour buttons filter by approximate average image colour.
History contains wallpapers applied through this picker. The monitor selector defaults to all.

Library: ~/Pictures/Wallpapers (including subfolders)
Thumbnails and history: ~/.cache/wallpaper-carousel

Uses Quickshell, Python Pillow, ffmpeg, awww, and mpvpaper. Static images use awww transitions; video wallpapers use mpvpaper. The optional Rofi picker uses hyprpaper.
Video wallpapers use all monitors. Static images can target one monitor; the existing login restore uses the last static selection globally.
This standalone adaptation does not include Serpantinum's online image search, desktop menu, or shader wallpaper transitions. After applying a wallpaper it runs the shared Matugen helper to update the Hyprland desktop palette.
It keeps Hyprland wallpaper links for login restore and lock-screen integration.

Original Rofi picker: ~/.config/hypr/scripts/wallpaper-picker.sh --rofi
