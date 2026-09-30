# ARCHNEMESIS // ZSH

## Files

- `config.zsh` — module loader
- `env.zsh` — environment and default applications
- `options.zsh` — history and shell behavior
- `completion.zsh` — completion configuration
- `plugins.zsh` — Oh My Zsh and external plugins
- `keybinds.zsh` — Emacs-style keybindings
- `aliases.zsh` — command shortcuts
- `functions.zsh` — shell functions
- `integrations.zsh` — mise, zoxide, direnv and Starship
- `highlighting.zsh` — syntax highlighting loaded last

## Editing and plugins

Zsh uses Emacs-style editing (`bindkey -e`). Ctrl+Left/Right moves by word,
Up/Down searches matching history, and Ctrl+Space accepts autosuggestions.
FZF supplies its own history/file/directory bindings when available.

Oh My Zsh supplies the base plugin set. External plugins provide fzf-tab,
autosuggestions, history substring search, autopair, alias suggestions, and
Forgit. Forgit keeps `FORGIT_NO_ALIASES=1`, preserving ARCHNEMESIS Git shortcuts.
Syntax highlighting is sourced last, after all integrations and widgets.

All editor environment variables use Neovim. The prompt remains the existing
`starship/zsh.toml`; Fastfetch is available through aliases only.

## Useful extras

- `vf` — fuzzy-find a file and open it in Neovim
- `cdf` — fuzzy-find a directory and enter it
- `y` — Yazi with cwd handoff
- `mkcd DIR` — create and enter a directory
- `rice-update` — update Oh My Zsh and local Zsh plugins
- `rice-help` — show this file
