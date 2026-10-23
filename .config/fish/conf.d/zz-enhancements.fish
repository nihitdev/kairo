# Small interactive quality-of-life additions for fzf.fish.
status is-interactive; or return

if functions -q fzf_configure_bindings
    set -g fzf_preview_dir_cmd eza --tree --level=2 --icons --color=always
    set -g fzf_preview_file_cmd bat --color=always --style=numbers --line-range=:250
    set -g fzf_fd_opts --hidden --exclude .git
end
