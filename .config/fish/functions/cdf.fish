function cdf --description "Fuzzy-find and enter a directory"
    if not type -q fzf
        echo "fzf is not installed"
        return 127
    end

    set -l dir

    if type -q fd
        set dir (
            fd --type d --hidden --exclude .git |
            fzf --preview "eza --tree --level=2 --icons --color=always -- {}"
        )
    else
        set dir (find . -type d | fzf)
    end

    test -n "$dir"; and cd -- "$dir"
end
