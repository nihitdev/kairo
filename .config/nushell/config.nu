# ─────────────────────────────────────────────────────────────────────────────
# Nushell Config
# UTF-8 • Starship • Fastfetch • Zoxide • Modern CLI tools
# ─────────────────────────────────────────────────────────────────────────────


# ─────────────────────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────────────────────

const STARTUP_CACHE_DIR = $"($nu.config-path | path dirname)/dotfiles-init"
const STARSHIP_CACHE = $"($nu.config-path | path dirname)/dotfiles-init/starship.nu"
const ZOXIDE_CACHE = $"($nu.config-path | path dirname)/dotfiles-init/zoxide.nu"
const XDG_CONFIG_ROOT = ($nu.default-config-dir | path dirname)
const STARSHIP_CONFIG = $"($XDG_CONFIG_ROOT)/starship/nushell.toml"
const FASTFETCH_CONFIG = $"($XDG_CONFIG_ROOT)/fastfetch/config.jsonc"

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def has-command [name: string] {
    which --all $name
    | where type == "external"
    | is-not-empty
}

def missing-command [name: string] {
    print $"(ansi yellow)($name) is not installed or unavailable in PATH.(ansi reset)"
}

# Regenerate cached Starship and Zoxide integrations.
def refresh-shell-cache [] {
    mkdir $STARTUP_CACHE_DIR

    if (has-command starship) {
        ^starship init nu | save --force $STARSHIP_CACHE
        print $"(ansi green)Refreshed Starship cache.(ansi reset)"
    } else {
        missing-command starship
    }

    if (has-command zoxide) {
        ^zoxide init nushell | save --force $ZOXIDE_CACHE
        print $"(ansi green)Refreshed Zoxide cache.(ansi reset)"
    } else {
        missing-command zoxide
    }

    print $"(ansi cyan)Run 'reload' to apply the changes.(ansi reset)"
}


# ─────────────────────────────────────────────────────────────────────────────
# NUSHELL SETTINGS
# ─────────────────────────────────────────────────────────────────────────────

$env.config.show_banner = false
$env.STARSHIP_CONFIG = $STARSHIP_CONFIG

$env.config.history = {
    max_size: 100_000
    sync_on_enter: true
    file_format: "plaintext"
    isolation: false
}

$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
        enable: true
        max_results: 100
        completer: null
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# CACHED SHELL INTEGRATIONS
#
# Keep these at the top level. Sourcing them inside an `if`
# block makes commands such as `z` and `zi` disappear afterward.
# ─────────────────────────────────────────────────────────────────────────────

source $STARSHIP_CACHE
source $ZOXIDE_CACHE


# ─────────────────────────────────────────────────────────────────────────────
# FASTFETCH STARTUP
# ─────────────────────────────────────────────────────────────────────────────

if $nu.is-interactive {
    if (has-command fastfetch) {
        if ($FASTFETCH_CONFIG | path exists) {
            ^fastfetch --config $FASTFETCH_CONFIG
        } else {
            ^fastfetch
        }
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# NAVIGATION
# ─────────────────────────────────────────────────────────────────────────────

def --env ".." [] {
    cd ..
}

def --env "..." [] {
    cd ../..
}

def --env "...." [] {
    cd ../../..
}

def --env home [] {
    cd $nu.home-dir
}


# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

def c [] {
    clear
}

def reload [] {
    exec nu
}

# Open config.nu in Neovim.
def profile [] {
    if (has-command nvim) {
        ^nvim $nu.config-path
    } else {
        missing-command nvim
    }
}

# Open env.nu in Neovim.
def env-profile [] {
    if (has-command nvim) {
        ^nvim $nu.env-path
    } else {
        missing-command nvim
    }
}

def paths [] {
    $env.PATH
}


# ─────────────────────────────────────────────────────────────────────────────
# MODERN CLI COMMANDS
#
# Native Nushell commands such as cat, find, du and ps remain
# unchanged because they produce structured data.
# ─────────────────────────────────────────────────────────────────────────────

def --wrapped bat [...args] {
    if (has-command bat) {
        ^bat --paging=never ...$args
    } else {
        missing-command bat
    }
}

def --wrapped grep [...args] {
    if (has-command rg) {
        ^rg ...$args
    } else {
        missing-command ripgrep
    }
}

def --wrapped rg [...args] {
    if (has-command rg) {
        ^rg ...$args
    } else {
        missing-command ripgrep
    }
}

def --wrapped fd [...args] {
    if (has-command fd) {
        ^fd ...$args
    } else {
        missing-command fd
    }
}

def --wrapped dust [...args] {
    if (has-command dust) {
        ^dust ...$args
    } else {
        missing-command dust
    }
}

def --wrapped btm [...args] {
    if (has-command btm) {
        ^btm ...$args
    } else {
        missing-command bottom
    }
}

def --wrapped sudo [...args] {
    if (has-command sudo) {
        ^sudo ...$args
    } else {
        missing-command sudo
    }
}

def --wrapped http [...args] {
    if (has-command xh) {
        ^xh ...$args
    } else {
        missing-command xh
    }
}

def --wrapped dns [...args] {
    if (has-command doggo) {
        ^doggo ...$args
    } else {
        missing-command doggo
    }
}

def --wrapped procs [...args] {
    if (has-command procs) {
        ^procs ...$args
    } else {
        missing-command procs
    }
}

def --wrapped sd [...args] {
    if (has-command sd) {
        ^sd ...$args
    } else {
        missing-command sd
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# FILE LISTING
# ─────────────────────────────────────────────────────────────────────────────

def --wrapped l [...args] {
    if (has-command eza) {
        ^eza --icons ...$args
    } else {
        ls ...$args
    }
}

def --wrapped la [...args] {
    if (has-command eza) {
        ^eza --all --icons ...$args
    } else {
        ls --all ...$args
    }
}

def --wrapped ll [...args] {
    if (has-command eza) {
        ^eza --long --all --header --git --icons ...$args
    } else {
        ls --long --all ...$args
    }
}

def --wrapped lt [...args] {
    if (has-command eza) {
        ^eza --tree --level=2 --icons ...$args
    } else {
        missing-command eza
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# GIT SHORTCUTS
# ─────────────────────────────────────────────────────────────────────────────

def --wrapped g [...args] {
    if (has-command git) {
        ^git ...$args
    } else {
        missing-command git
    }
}

def gs [] {
    g status --short --branch
}

def ga [...files] {
    g add ...$files
}

def gc [message: string] {
    g commit -m $message
}

def gp [] {
    g push
}

def gl [] {
    g log --oneline --graph --decorate --all
}


# ─────────────────────────────────────────────────────────────────────────────
# APPLICATION SHORTCUTS
# ─────────────────────────────────────────────────────────────────────────────

def --wrapped preview-md [...args] {
    if (has-command glow) {
        ^glow ...$args
    } else {
        missing-command glow
    }
}

def --wrapped npp [...args] {
    if (has-command notepad++.exe) {
        ^notepad++.exe ...$args
    } else {
        missing-command "Notepad++"
    }
}

def --wrapped code [...args] {
    if (has-command code) {
        ^code ...$args
    } else {
        missing-command "Visual Studio Code"
    }
}

def --wrapped ff [...args] {
    if not (has-command fastfetch) {
        missing-command fastfetch
        return
    }

    if ($args | is-not-empty) {
        ^fastfetch ...$args
    } else if ($FASTFETCH_CONFIG | path exists) {
        ^fastfetch --config $FASTFETCH_CONFIG
    } else {
        ^fastfetch
    }
}


# ─────────────────────────────────────────────────────────────────────────────
# PROMPT
# ─────────────────────────────────────────────────────────────────────────────

# Starship is loaded from the cached initialization script.
# Prompt appearance and the beloved λ are configured in:
#
# ~/.config/starship/nushell.toml

# Shared Prism terminal palette.
source ($nu.config-path | path dirname | path dirname | path join "prism/init.nu")
