function prism --description 'Shared terminal themes, previews, and switching'
    command prism $argv
    set -l result $status
    if test $result -eq 0; and test "$argv[1]" = theme; and contains -- "$argv[2]" switch back
        source "$__fish_config_dir/conf.d/15-prism-theme.fish"
    end
    return $result
end
