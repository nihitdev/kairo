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
autosuggestions, history substring search, autopair, and
Forgit. Forgit keeps `FORGIT_NO_ALIASES=1`, preserving ARCHNEMESIS Git shortcuts.
Syntax highlighting is sourced last, after all integrations and widgets.

Editor settings respect existing choices, with an installed-editor fallback.
`starship/zsh.toml` shows command duration at the right edge of the input line;
Fastfetch is available through aliases only.

## Useful extras

- `vf` — fuzzy-find a file and open it with your configured editor
- `cdf` — fuzzy-find a directory and enter it
- `y` — Yazi with cwd handoff
- `mkcd DIR` — create and enter a directory
- `rice-update` — update Oh My Zsh and local Zsh plugins
- `rice-help` — show this file

## Portable local settings

Paths follow `HOME` and the XDG variables. Set overrides before Zsh starts (or in
`.zshenv`): `ZSH_PLUGIN_DIR`, `ZSH_SYSTEM_PLUGIN_DIR`, `ZSH_CACHE_DIR`,
`ZSH_COMPDUMP`, and `STARSHIP_CONFIG`. The system plugin directory defaults to
`/usr/share/zsh/plugins`; user plugins default to `$XDG_DATA_HOME/zsh/plugins`.
An optional `ZSH_EXTRA_ENV_FILE` replaces implicit distribution-specific sourcing.

Existing editor, terminal, pager and FZF choices are preserved. Otherwise an
installed editor and terminal are selected. `v` and `vf` use `VISUAL`/`EDITOR`,
including quoted arguments. Fuzzy pickers use NUL delimiters for unusual filenames
and work without fd, bat or eza. `rice-update` handles an empty plugin directory.
Set `ZSH_HISTORY_SIZE` / `ZSH_SAVEHIST` to override the 100,000-entry history limit.
