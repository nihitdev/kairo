complete -c prism -f
complete -c prism -n 'not __fish_seen_subcommand_from theme' -a theme -d 'Manage terminal themes'
complete -c prism -n '__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from list current switch preview back' -a 'list current switch preview back'
complete -c prism -n '__fish_seen_subcommand_from switch preview' -a 'arch-blue catppuccin rose-pine'
