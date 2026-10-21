# Read colors at runtime so switching also updates the current Nushell session.
$env.PATH = ($env.PATH | prepend ($env.HOME | path join '.local/bin') | uniq)

def --env prism-apply [] {
    let root = ($nu.config-path | path dirname | path dirname)
    let colors = (open ($root | path join 'prism/nu-colors.json'))
    let base = ($env.config.color_config | columns | each {|key| {key: $key, value: $colors.string}} | transpose -r -d)
    $env.config.color_config = ($base | merge $colors)
    let picker = (open --raw ($root | path join 'prism/fzf.txt') | str trim)
    let opts = ($env.FZF_DEFAULT_OPTS? | default '' | str replace --all --regex '--color=[^ ]+' '')
    $env.FZF_DEFAULT_OPTS = $"($opts) ($picker)"
}

def --env --wrapped prism [...args: string] {
    ^prism ...$args
    let result = $env.LAST_EXIT_CODE
    if $result == 0 and ($args | get -o 0) == 'theme' and ($args | get -o 1) in [switch back] {
        prism-apply
    }
    $env.LAST_EXIT_CODE = $result
}
let prism_root = ($nu.config-path | path dirname | path dirname | path join 'prism')
if (($prism_root | path join 'nu-colors.json') | path exists) {
    prism-apply
}
