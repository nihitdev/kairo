# ARCHNEMESIS // FISH

Fish-native shell configuration.

## Layout

- config.fish — interactive entrypoint
- conf.d/00-env.fish — environment and applications
- conf.d/10-options.fish — Fish UI and colors
- conf.d/15-prism-theme.fish — generated colors from Prism
- conf.d/20-aliases.fish — aliases
- conf.d/90-integrations.fish — mise, zoxide, direnv, Starship
- functions/prism.fish and completions/prism.fish — Prism command and completion
- functions/kairo.fish — compatibility alias for `prism`
- functions/y.fish — Yazi cwd handoff
- functions/mkcd.fish — create + enter directory
- functions/vf.fish — fuzzy file -> Neovim
- functions/cdf.fish — fuzzy directory jump

Fish already provides autosuggestions and completions natively.

Fish is an optional interactive shell alongside Zsh. Installing it does not
change the login shell. No plugin manager is needed for its native suggestions,
syntax highlighting, and completions. Fastfetch is available through aliases only.
