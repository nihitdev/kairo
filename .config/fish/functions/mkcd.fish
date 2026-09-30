function mkcd --description "Create and enter a directory"
    if test (count $argv) -ne 1
        echo "Usage: mkcd DIRECTORY"
        return 2
    end

    mkdir -p -- "$argv[1]"
    and cd -- "$argv[1]"
end
