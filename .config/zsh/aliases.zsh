# ==============================================================================
# ARCHNEMESIS // ALIASES
# ==============================================================================

# ── Navigation ─────────────────────────────────────────────────────────────────

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c='clear'
alias reload='exec zsh'

# ── Files ──────────────────────────────────────────────────────────────────────

if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -lah --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
fi

if (( $+commands[bat] )); then
  alias cat='bat --style=plain'
  alias preview='bat --style=numbers'
fi

# ── Editors ────────────────────────────────────────────────────────────────────

alias v='edit'
if (( $+commands[nvim] )); then
  alias nv='nvim'
  alias vi='nvim'
  alias vim='nvim'
fi

alias se='sudoedit'
alias svi='sudoedit'

# ── Rust / Cargo ───────────────────────────────────────────────────────────────

alias cb='cargo build'
alias cr='cargo run'
alias cc='cargo check'
alias ct='cargo nextest run'
alias cw='cargo watch -x check -x test'
alias cx='cargo expand'

# ── Pacman ─────────────────────────────────────────────────────────────────────

alias p='sudo pacman'
alias pi='sudo pacman -S'
alias pu='sudo pacman -Syu'
alias pr='sudo pacman -Rns'

alias psearch='pacman -Ss'
alias pq='pacman -Qs'
alias orphan='pacman -Qdt'
alias pown='pacman -Qo'

# ── Yay ────────────────────────────────────────────────────────────────────────

alias ya='yay'
alias yai='yay -S'
alias yas='yay -Ss'
alias yar='yay -Rns'
alias yaup='yay -Syu'
alias yaclean='yay -Sc --noconfirm'

# ── Git ────────────────────────────────────────────────────────────────────────

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate --all'
alias lg='lazygit'

(( $+commands[delta] )) \
  && alias gdiff='git -c core.pager=delta diff'

# ── Podman ─────────────────────────────────────────────────────────────────────

alias pod='podman'
alias podps='podman ps'
alias podpa='podman ps -a'
alias podi='podman images'
alias podv='podman volume ls'
alias podn='podman network ls'

# ── Distrobox ──────────────────────────────────────────────────────────────────

alias db='distrobox'
alias dbl='distrobox list'
alias dbc='distrobox create'
alias dbe='distrobox enter'
alias dbr='distrobox rm'

# ── System ─────────────────────────────────────────────────────────────────────

alias sys='systemctl'
alias sysu='systemctl --user'
alias jctl='journalctl'

alias ipb='ip -br address'
alias mounts='findmnt'
alias mem='free -h'

alias ports='ss -tulpn'
alias disks='lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL'

# ── Utilities ──────────────────────────────────────────────────────────────────

if (( $+commands[btop] )); then
  alias top='btop'
elif (( $+commands[htop] )); then
  alias top='htop'
fi
alias ff='fastfetch'

if (( $+commands[duf] )); then
  alias space='duf'
else
  alias space='df -h'
fi

(( $+commands[dust] )) \
  && alias usage='dust'

# ── Arch btw ───────────────────────────────────────────────────────────────────

alias btw='fastfetch'
alias archbtw='fastfetch'
