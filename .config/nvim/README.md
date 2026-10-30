# Neovim

LazyVim with ARCHNEMESIS styling: a Rosé Pine inspired purple fallback, optional wallpaper palette integration, rounded completion menus and pickers, file/symbol breadcrumbs, and a start screen with recent files and projects. No additional plugins are required for this polish.

An existing `~/.cache/kairo/colors.json` palette (or `NVIM_PALETTE`) takes precedence over the fallback. Focus the editor after a palette change to refresh it. Breadcrumb symbols appear when an attached language server supports document symbols; narrow windows keep just the file path.

Leader is Space. Existing shortcuts remain unchanged:

| Shortcut | Action |
| --- | --- |
| `Ctrl+S` / `Ctrl+O` | Save |
| `Ctrl+X` | Quit current window |
| `jk` in insert mode | Return to normal mode |
| `Space e` | File explorer |
| `Space ff` / `Space fg` | Find files / search text |
| `Space fb` / `Space fp` | Buffers / projects |
| `Space gg` | LazyGit |
| `Space cf` | Format |
| `Space xs` | Symbol outline |
| `Space uz` | Zen mode |
| `Space qs` | Restore project session |
| `Space ha` / `Space hh` | Bookmark file / Harpoon menu |

Use `:Mason` for language tools, `:ConformInfo` for formatter availability, and `:checkhealth` for environment diagnostics. Existing debug, task, test, and language extras are preserved.

Copy this directory to `~/.config/nvim` or use `install.sh --only nvim`. Add `--install-packages` to bootstrap `lazy.nvim` and synchronize the versions recorded in `lazy-lock.json` during installation; otherwise, opening Neovim performs the standard LazyVim bootstrap.
