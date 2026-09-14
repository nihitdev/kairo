# Fish rice. Prompt: ~/.config/starship/fish.toml
fish_add_path --path --append $HOME/.local/bin $HOME/.local/share/mise/shims
set -gx GOBIN $HOME/.local/bin
set -gx CARGO_INSTALL_ROOT $HOME/.local
set -gx BUN_INSTALL $HOME/.bun
test -d $BUN_INSTALL/bin; and fish_add_path --path --append $BUN_INSTALL/bin

if not status is-interactive
    return
end

set -g fish_greeting
set -gx STARSHIP_CONFIG $HOME/.config/starship/fish.toml
set -gx BAT_THEME ansi
set -q EDITOR; or set -gx EDITOR 'omarchy-launch-editor --inline'
set -q VISUAL; or set -gx VISUAL $EDITOR
set -q BROWSER; or set -gx BROWSER omarchy-launch-browser

# Catppuccin syntax, autosuggestion, and completion colors.
set -g fish_color_normal cdd6f4
set -g fish_color_command 89b4fa
set -g fish_color_param cdd6f4
set -g fish_color_quote a6e3a1
set -g fish_color_redirection f5c2e7
set -g fish_color_end cba6f7
set -g fish_color_error f38ba8
set -g fish_color_comment 7f849c
set -g fish_color_autosuggestion 6c7086
set -g fish_color_operator 94e2d5
set -g fish_color_escape fab387
set -g fish_color_search_match --background=313244
set -g fish_pager_color_prefix cba6f7
set -g fish_pager_color_completion cdd6f4
set -g fish_pager_color_description 7f849c
set -g fish_pager_color_selected_background --background=313244

set -gx FZF_DEFAULT_OPTS '--height=45% --layout=reverse --border=rounded --color=bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4,hl:#f5c2e7,hl+:#f5c2e7,border:#cba6f7,prompt:#94e2d5,pointer:#94e2d5,marker:#a6e3a1'
set -g fzf_preview_dir_cmd eza --all --icons --color=always
set -g fzf_diff_highlighter delta --paging=never
if functions -q fzf_configure_bindings
    fzf_configure_bindings --directory=ctrl-t --history=ctrl-r --git_log=ctrl-alt-l --git_status=ctrl-alt-s --processes=ctrl-alt-p --variables=ctrl-alt-v
end

if type -q eza
    alias ls 'eza --icons --group-directories-first'
    alias ll 'eza -lh --icons --git --group-directories-first'
    alias la 'eza -lah --icons --git --group-directories-first'
    alias lt 'eza --tree --level=2 --icons --group-directories-first'
end
type -q delta; and alias gdiff 'git -c core.pager=delta diff'
alias rice-help 'cat ~/.config/fish/README.md'
alias rice-update 'fisher update'

abbr -a lg lazygit
abbr -a top btop
abbr -a ff fastfetch
abbr -a disks duf
abbr -a usage dust
abbr -a preview bat --style=numbers
abbr -a gst git status
abbr -a ga git add
abbr -a gcmsg git commit -m
abbr -a gl git pull
abbr -a gp git push
abbr -a .. cd ..
abbr -a ... cd ../..
abbr -a c clear
abbr -a reload exec fish

if type -q mise
    mise activate fish | source
end
if type -q zoxide
    zoxide init fish | source
end
if type -q starship
    starship init fish | source
end

if test -f $__fish_config_dir/user.fish
    source $__fish_config_dir/user.fish
end
