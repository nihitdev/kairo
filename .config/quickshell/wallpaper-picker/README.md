# Standalone wallpaper carousel

Open with Super + Alt + Space (press again to close).
Arrow keys / mouse wheel browse; click a card to select, click again or Enter to apply. Escape closes.
Search filters local filenames. Colour buttons filter by approximate average image colour.
History contains wallpapers applied through this picker. The monitor selector defaults to all.

Library: ~/Pictures/Wallpapers (including subfolders)
Thumbnails and history: ~/.cache/wallpaper-carousel

Uses Quickshell, Python Pillow, ffmpeg, hyprpaper, and mpvpaper.
Video wallpapers use all monitors. Static images can target one monitor; the existing login restore uses the last static selection globally.
This standalone adaptation does not include Serpantinum's online image search, desktop menu, shader wallpaper transitions, or automatic theme generation.
It retains the installed wallpaper backends and login restore links.

Original Rofi picker: ~/.config/hypr/scripts/wallpaper-picker.sh --rofi
