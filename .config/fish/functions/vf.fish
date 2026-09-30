function vf --description "Fuzzy-find a file and open it in Neovim"
    if not type -q fzf
        echo "fzf is not installed"
        return 127
    end

    set -l file

    if type -q fd
        set file (
            fd --type f --hidden --exclude .git |
            fzf --preview "bat --color=always --style=numbers --line-range=:250 -- {}"
        )
    else
        set file (find . -type f | fzf)
    end

    test -n "$file"; and nvim -- "$file"
end
