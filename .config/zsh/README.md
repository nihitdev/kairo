# Zsh Rice

Prompt: `~/.config/starship/zsh.toml`
Shell config: `~/.config/zsh/config.zsh`

Oh My Zsh provides the base plugin set: git, sudo, extract, copypath, copyfile,
dirhistory, colored-man-pages, command-not-found, history, jsontools, urltools.

Standalone plugins are loaded when present. Arch packages cover
zsh-completions, zsh-autosuggestions, zsh-history-substring-search, and
zsh-syntax-highlighting; fzf-tab is used when a local checkout exists.

Keys:
- Tab: completion menu, with fzf-tab when available
- Right arrow or Ctrl+Space: accept autosuggestion
- Up / Down: search matching history
- Ctrl+R: fuzzy command history
- Ctrl+T: fuzzy file search
- Alt+C: fuzzy directory search
- Alt+Left / Alt+Right: previous / next directory
- Escape twice: prepend sudo
- Ctrl+Left / Ctrl+Right: move by word

Commands:
- `z NAME` / `zi`: smart directory jumps
- `y`: Yazi file manager, exiting into the selected directory
- `ls` / `ll` / `la` / `lt`: eza-powered file lists and tree
- `mkcd DIR`: create and enter a directory
- `rice-update`: update local plugin repositories
- `reload`: restart Zsh
