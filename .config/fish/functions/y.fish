function y --description "Yazi with cwd handoff"
    if not type -q yazi
        echo "yazi is not installed"
        return 127
    end

    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    or return

    yazi $argv --cwd-file="$tmp"

    if test -s "$tmp"
        set -l cwd (command cat "$tmp")

        if test -d "$cwd"; and test "$cwd" != "$PWD"
            cd -- "$cwd"
        end
    end

    rm -f -- "$tmp"
end
