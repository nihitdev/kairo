# ARCHNEMESIS // FISH

Fish-native shell configuration.

## Layout

- config.fish — interactive entrypoint
- conf.d/00-env.fish — environment and applications
- conf.d/10-options.fish — Fish UI and colors
- conf.d/15-prism-theme.fish — generated colors from Prism
- conf.d/20-aliases.fish — aliases
- conf.d/zz-enhancements.fish — fzf preview configuration
- conf.d/90-integrations.fish — mise, zoxide, direnv, Starship
- fish_plugins — Fisher plugin manifest
- functions/prism.fish and completions/prism.fish — Prism command and completion
- functions/kairo.fish — compatibility alias for `prism`
- functions/y.fish — Yazi cwd handoff
- functions/mkcd.fish — create + enter directory
- functions/vf.fish — fuzzy file -> Neovim
- functions/cdf.fish — fuzzy directory jump

Fish 4 provides autosuggestions, syntax highlighting, and completions natively.
Fisher manages two small additions: `fzf.fish` for searchable command history,
files, directories, processes, and Git state; and `autopair.fish` for paired
quotes and brackets. Run `fisher update` to install or update the manifest.

Fish is an optional interactive shell alongside Zsh. Installing it does not
change the login shell. Fastfetch is available through aliases only.
