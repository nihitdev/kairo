#!/usr/bin/env bash

# Dependency-free interactive terminal UI for the Kairo installer.

ui_active=false
ui_compact=false
ui_cursor_hidden=false
ui_alt_screen=false
UI_RESET=$'\033[0m'
UI_BOLD=$'\033[1m'
UI_DIM=$'\033[2m'
# Rose Pine: match the shipped desktop instead of the terminal's ANSI palette.
UI_BASE=$'\033[48;2;25;23;36m'
UI_CYAN=$'\033[38;2;156;207;216m'
UI_GREEN=$'\033[38;2;156;207;216m'
UI_YELLOW=$'\033[38;2;246;193;119m'
UI_RED=$'\033[38;2;235;111;146m'
UI_PURPLE=$'\033[38;2;196;167;231m'
UI_WHITE=$'\033[38;2;224;222;244m'
UI_MUTED=$'\033[38;2;110;106;134m'
UI_SURFACE=$'\033[48;2;49;47;66m'
UI_SELECTED=$'\033[48;2;196;167;231m\033[38;2;25;23;36m'
UI_PANEL=$'\033[48;2;31;29;46m'
UI_REVERSE=$'\033[7m'
UI_RESET=$'\033[0m\033[48;2;25;23;36m\033[38;2;224;222;244m'
UI_X=1 UI_Y=1 UI_W=76 UI_ROWS=24 UI_COLS=80 UI_BOTTOM=19
UI_STAGE_LABELS=('Preparing' 'Backup' 'Packages' 'Dotfiles' 'Shells' 'Caches' 'Validate')
UI_KEY=''

ui_read_key() {
    local first second char sequence='' count=0
    UI_KEY=''
    IFS= read -rsn1 first || return 1
    case "$first" in
        '') UI_KEY=enter ;;
        ' ') UI_KEY=space ;;
        q | Q) UI_KEY=quit ;;
        a | A) UI_KEY=all ;;
        n | N) UI_KEY=none ;;
        r | R) UI_KEY=defaults ;;
        $'\t') UI_KEY=category ;;
        y | Y) UI_KEY=yes ;;
        j) UI_KEY=down ;;
        k) UI_KEY=up ;;
        $'\e')
            # Arrow, function-key, and mouse events all begin with Escape.
            # Wait long enough for the next byte instead of treating a
            # partially delivered sequence as a cancellation.
            if ! IFS= read -rsn1 -t 0.25 second; then
                UI_KEY=escape
                return 0
            fi
            sequence=$second
            if [[ $second == '[' || $second == O ]]; then
                while ((count < 32)); do
                    if ! IFS= read -rsn1 -t 0.10 char; then break; fi
                    sequence+=$char
                    ((count++)) || true
                    # CSI arrows end in A-D, function keys commonly in ~,
                    # and SGR mouse reports in M/m. Consume the whole event.
                    [[ $char == [A-DF-HMm~] ]] && break
                done
                if [[ $sequence == '[M' ]]; then
                    # Legacy X10 mouse protocol appends three coordinate bytes.
                    for ((count=0; count<3; count++)); do
                        IFS= read -rsn1 -t 0.10 char || break
                        sequence+=$char
                    done
                fi
            fi
            case "$sequence" in
                '[A' | 'OA') UI_KEY=up ;;
                '[B' | 'OB') UI_KEY=down ;;
                '[5~') UI_KEY=page_up ;;
                '[6~') UI_KEY=page_down ;;
                '[H' | 'OH' | '[1~') UI_KEY=home ;;
                '[F' | 'OF' | '[4~') UI_KEY=end ;;
                '[<'*M | '[<'*m | '[M'*) UI_KEY=mouse ;;
                *) UI_KEY=ignore ;;
            esac
            ;;
        *) UI_KEY=ignore ;;
    esac
}

ui_start() {
    local rows columns
    ui_active=true
    rows=$(tput lines 2>/dev/null || printf '24')
    columns=$(tput cols 2>/dev/null || printf '80')
    ((rows < 32 || columns < 72)) && ui_compact=true
    printf '\033[?1049h\033[?25l'
    ui_alt_screen=true
    ui_cursor_hidden=true
}

ui_restore() {
    # End a synchronized update if a signal interrupted a frame.
    $ui_active && printf '\033[?2026l'
    $ui_cursor_hidden && printf '\033[?25h'
    $ui_alt_screen && printf '\033[?1049l'
    $ui_active && printf '\033[0m'
    ui_cursor_hidden=false
    ui_alt_screen=false
    ui_active=false
}

ui_clear() {
    printf '%s\033[2J\033[H' "$UI_RESET"
}

ui_at() {
    local row=$1 column=$2 style=$3 text=$4 limit=${5:-$UI_W}
    printf '\033[%d;%dH%s%s%s' "$row" "$column" "$style" "${text:0:limit}" "$UI_RESET"
}

ui_line() {
    local count=$1 char=${2:-─} result
    printf -v result '%*s' "$count" ''
    printf '%s' "${result// /$char}"
}

ui_canvas() {
    local title=$1 subtitle=${2:-MAKE YOURSELF AT HOME} mode=SETUP
    UI_ROWS=$(tput lines 2>/dev/null || printf '24')
    UI_COLS=$(tput cols 2>/dev/null || printf '80')
    UI_W=$((UI_COLS - 4))
    ((UI_W <= 112)) || UI_W=112
    UI_X=$(((UI_COLS - UI_W) / 2 + 1))
    UI_Y=1
    ((UI_ROWS < 30)) || UI_Y=2
    UI_BOTTOM=$((UI_ROWS - 5))
    [[ ${dry_run:-false} != true ]] || mode=PREVIEW
    printf '\033[?2026h%s\033[H\033[J' "$UI_RESET"
    ui_at "$UI_Y" "$UI_X" "${UI_PURPLE}${UI_BOLD}" 'K A I R O' 10
    ui_at "$UI_Y" "$((UI_X + UI_W - ${#mode}))" "$UI_MUTED" "$mode" "${#mode}"
    ui_at "$((UI_Y + 1))" "$UI_X" "$UI_MUTED" "$(ui_line "$UI_W" '─')"
    ui_at "$((UI_Y + 2))" "$UI_X" "${UI_WHITE}${UI_BOLD}" "$title"
    ui_at "$((UI_Y + 3))" "$UI_X" "$UI_MUTED" "$subtitle"
}

ui_panel() {
    local top=$1 left=$2 width=$3 height=$4 title=${5:-} row
    ui_at "$top" "$left" "$UI_MUTED" "╭$(ui_line "$((width - 2))")╮" "$width"
    for ((row=top+1; row<top+height-1; row++)); do
        ui_at "$row" "$left" "$UI_MUTED" "│$(ui_line "$((width - 2))" ' ')│" "$width"
    done
    ui_at "$((top + height - 1))" "$left" "$UI_MUTED" "╰$(ui_line "$((width - 2))")╯" "$width"
    if [[ -n $title ]]; then
        ui_at "$top" "$((left + 2))" "$UI_PURPLE" " $title " "$((width - 4))"
    fi
}

ui_controls() {
    local primary=$1 secondary=$2
    ui_at "$((UI_ROWS - 3))" "$UI_X" "$UI_MUTED" "$(ui_line "$UI_W")"
    ui_at "$((UI_ROWS - 2))" "$UI_X" "${UI_PURPLE}${UI_BOLD}" "$primary"
    ui_at "$((UI_ROWS - 1))" "$UI_X" "$UI_MUTED" "$secondary"
    printf '\033[?2026l'
}

# Wrap prose at word boundaries; long paths still fit within the panel.
ui_wrap() {
    local text=$1 width=$2 line chunk
    UI_LINES=()
    while IFS= read -r line; do
        while ((${#line} > width)); do
            chunk=${line:0:width}
            if [[ $chunk == *' '* && -n ${chunk% *} ]]; then
                chunk=${chunk% *}
            fi
            UI_LINES+=("$chunk")
            line=${line:${#chunk}}
            line=${line# }
        done
        UI_LINES+=("$line")
    done <<< "$text"
}

ui_center() {
    local text=$1 columns padding=0
    columns=$(tput cols 2>/dev/null || printf '80')
    ((${#text} < columns)) && padding=$(((columns - ${#text}) / 2))
    printf '%*s%s\n' "$padding" '' "$text"
}

ui_center_styled() {
    local style=$1 text=$2 columns padding=0
    columns=$(tput cols 2>/dev/null || printf '80')
    ((${#text} < columns)) && padding=$(((columns - ${#text}) / 2))
    printf '%*s%s%s%s\n' "$padding" '' "$style" "$text" "$UI_RESET"
}

ui_width() {
    local columns
    columns=$(tput cols 2>/dev/null || printf '80')
    ((columns > 84)) && columns=84
    ((columns < 4)) && columns=4
    printf '%d' "$((columns - 4))"
}

ui_rule() {
    local width rule
    width=$(ui_width)
    printf -v rule '%*s' "$width" ''
    printf '%s%s%s\n' "$UI_DIM" "${rule// /─}" "$UI_RESET"
}

ui_section() {
    printf '%s%s%s  %s%s%s\n' "$UI_PURPLE" '◆' "$UI_RESET" "$UI_BOLD" "$1" "$UI_RESET"
}

ui_kv() {
    printf '  %s%-14s%s %s\n' "$UI_DIM" "$1" "$UI_RESET" "$2"
}

ui_footer() {
    printf '\n'
    ui_rule
    printf '%s%s%s\n' "$UI_DIM" "$1" "$UI_RESET"
}

ui_heading() {
    ui_canvas 'Your next workspace.' 'ARCH LINUX  /  PERSONAL BY DESIGN'
    printf '\033[?2026l\033[%d;%dH' "$((UI_Y + 5))" "$UI_X"
}

ui_card() {
    ui_section "$1"
    printf '\n  %s\n' "$2"
    printf '\n'
}

ui_stage() {
    local current=$1 total=$2 label=$3 index marker connector
    printf '\n'
    for ((index=1; index<=total; index++)); do
        if ((index < current)); then marker="${UI_GREEN}●${UI_RESET}"
        elif ((index == current)); then marker="${UI_CYAN}◆${UI_RESET}"
        else marker="${UI_DIM}○${UI_RESET}"; fi
        printf '%b' "$marker"
        if ((index < total)); then
            ((index < current)) && connector="${UI_GREEN}━━${UI_RESET}" || connector="${UI_DIM}──${UI_RESET}"
            printf '%b' "$connector"
        fi
    done
    printf '  %s%s[%d/%d]%s %s\n' "$UI_BOLD" "$UI_WHITE" "$current" "$total" "$UI_RESET" "$label"
    if ! $ui_compact; then
        printf '%s' "$UI_DIM"
        for ((index=0; index<total; index++)); do printf '%-6.6s' "${UI_STAGE_LABELS[index]}"; done
        printf '%s\n' "$UI_RESET"
    fi
}

ui_status() {
    local kind=$1 message=$2 icon color
    case "$kind" in
        ok) icon='✓'; color=$UI_GREEN ;;
        changed) icon='↻'; color=$UI_CYAN ;;
        skip) icon='○'; color=$UI_DIM ;;
        warn) icon='!'; color=$UI_YELLOW ;;
        error) icon='✗'; color=$UI_RED ;;
        *) icon='·'; color=$UI_RESET ;;
    esac
    printf '%s%s%s %s\n' "$color" "$icon" "$UI_RESET" "$message"
}

ui_run_spinner() {
    local label=$1 log status frame=0
    shift
    local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    log=$(mktemp)
    "$@" >"$log" 2>&1 &
    local command_pid=$!
    while kill -0 "$command_pid" 2>/dev/null; do
        printf '\r%s%s%s %s' "$UI_CYAN" "${frames[frame]}" "$UI_RESET" "$label"
        frame=$(((frame + 1) % ${#frames[@]}))
        sleep 0.08
    done
    if wait "$command_pid"; then
        status=0
        printf '\r\033[2K%s✓%s %s\n' "$UI_GREEN" "$UI_RESET" "$label"
    else
        status=$?
        printf '\r\033[2K%s✗%s %s\n' "$UI_RED" "$UI_RESET" "$label"
        sed 's/^/  /' "$log" >&2
    fi
    rm -f -- "$log"
    return "$status"
}

ui_wait_for_enter() {
    ui_footer 'Enter  continue    Q / Esc  cancel'
    while ui_read_key; do
        case "$UI_KEY" in
            enter) printf '\n'; return 0 ;;
            quit | escape) printf '\n'; return 1 ;;
        esac
    done
    return 1
}

# Scroll a wrapped review without losing earlier lines above the terminal.
ui_review() {
    local text=$1 title=${2:-Review installation} action=${3:-install}
    local rows columns height offset=0 maximum index last top content_width style content_x panel_width hero_width
    local -a logo=('██╗  ██╗ █████╗ ██╗██████╗  ██████╗' '██║ ██╔╝██╔══██╗██║██╔══██╗██╔═══██╗' '█████╔╝ ███████║██║██████╔╝██║   ██║' '██╔═██╗ ██╔══██║██║██╔══██╗██║   ██║' '██║  ██╗██║  ██║██║██║  ██║╚██████╔╝' '╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝')
    local -a UI_LINES=()
    while true; do
        rows=$(tput lines 2>/dev/null || printf '24')
        columns=$(tput cols 2>/dev/null || printf '80')
        if ((rows < 16 || columns < 32)); then
            ui_clear
            printf 'Resize to at least 32 x 16'
            ui_read_key || return 1
            case "$UI_KEY" in quit | escape) return 1 ;; esac
            continue
        fi
        ui_canvas "$title" 'YOUR WORKSPACE. YOUR CHOICES.'
        top=$((UI_Y + 5))
        height=$((UI_BOTTOM - top - 1))
        content_x=$UI_X panel_width=$UI_W
        if [[ $title == 'Welcome to Kairo' ]] && ((UI_W >= 86 && rows >= 24)); then
            hero_width=$((UI_W / 2))
            ui_panel "$top" "$UI_X" "$hero_width" "$((UI_BOTTOM - top + 1))" 'THE KAIRO WORKSPACE'
            for ((index=0; index<${#logo[@]} && index<height; index++)); do
                ui_at "$((top + 2 + index))" "$((UI_X + 3))" "$UI_PURPLE" "${logo[index]}" "$((hero_width - 6))"
            done
            ui_at "$((UI_BOTTOM - 3))" "$((UI_X + 3))" "$UI_WHITE" 'Make yourself at home.' "$((hero_width - 6))"
            ui_at "$((UI_BOTTOM - 2))" "$((UI_X + 3))" "$UI_CYAN" 'Built around the way you work.' "$((hero_width - 6))"
            content_x=$((UI_X + hero_width + 2))
            panel_width=$((UI_W - hero_width - 2))
        fi
        content_width=$((panel_width - 6))
        ui_wrap "$text" "$content_width"
        maximum=$((${#UI_LINES[@]} - height))
        ((maximum >= 0)) || maximum=0
        ((offset <= maximum)) || offset=$maximum
        last=$((offset + height))
        ((last <= ${#UI_LINES[@]})) || last=${#UI_LINES[@]}
        ui_panel "$top" "$content_x" "$panel_width" "$((UI_BOTTOM - top + 1))" 'OVERVIEW'
        for ((index=offset; index<last; index++)); do
            style=$UI_WHITE
            case "${UI_LINES[index]}" in
                *: | 'PREVIEW MODE:'*) style="${UI_PURPLE}${UI_BOLD}" ;;
                '  •'*) style=$UI_CYAN ;;
            esac
            ui_at "$((top + 1 + index - offset))" "$((content_x + 3))" "$style" "${UI_LINES[index]}" "$content_width"
        done
        ui_at "$UI_BOTTOM" "$((content_x + 3))" "$UI_MUTED" " $((offset + 1))–$last of ${#UI_LINES[@]} lines " "$content_width"
        if ((columns < 60)); then
            ui_controls "Enter $action" '↑↓ scroll  PgUp/Dn  Q cancel'
        else
            ui_controls "Enter  $action                         Q / Esc  cancel" '↑↓ / j k  scroll     PgUp / PgDn  page     Home / End  jump'
        fi
        ui_read_key || return 1
        case "$UI_KEY" in
            enter) return 0 ;;
            quit | escape) return 1 ;;
            up) ((offset > 0)) && ((offset--)) || true ;;
            down) ((offset < maximum)) && ((offset++)) || true ;;
            page_up) offset=$((offset - height)); ((offset >= 0)) || offset=0 ;;
            page_down) offset=$((offset + height)) ;;
            home) offset=0 ;;
            end) offset=$maximum ;;
        esac
    done
}

ui_confirm() {
    local prompt=$1 details=${2:-} index top height
    local -a UI_LINES=()
    ui_canvas 'Make it yours.' 'OPTIONAL EXTRAS  /  YOU DECIDE'
    top=$((UI_Y + 5))
    height=$((UI_BOTTOM - top - 1))
    ui_panel "$top" "$UI_X" "$UI_W" "$((UI_BOTTOM - top + 1))" 'YOUR CHOICE'
    ui_wrap "$prompt" "$((UI_W - 6))"
    for ((index=0; index<${#UI_LINES[@]} && index<height; index++)); do
        ui_at "$((top + 1 + index))" "$((UI_X + 3))" "${UI_WHITE}${UI_BOLD}" "${UI_LINES[index]}" "$((UI_W - 6))"
    done
    top=$((top + index + 2))
    ui_wrap "$details" "$((UI_W - 6))"
    for ((index=0; index<${#UI_LINES[@]} && top+index<UI_BOTTOM; index++)); do
        ui_at "$((top + index))" "$((UI_X + 3))" "$UI_MUTED" "${UI_LINES[index]}" "$((UI_W - 6))"
    done
    ui_controls 'Y  yes     Enter / N  no' 'Optional. Press Enter to skip.'
    while ui_read_key; do
        case "$UI_KEY" in
            yes) return 0 ;;
            enter | none | quit | escape) return 1 ;;
        esac
    done
    return 1
}

# Short descriptions stay separate from labels so the picker can truncate them.
ui_module_hint() {
    case "$1" in
        hypr) printf 'Hyprland, Waybar, Quickshell notifications and wallpapers.' ;;
        kairo-shell) printf 'Alternative desktop shell; replaces Waybar and the notification center.' ;;
        kitty-smooth) printf 'Builds pinned Kitty with smooth cursor motion; requires build tools.' ;;
        sddm) printf 'System login theme; needs sudo. Does not restart the display manager.' ;;
        plymouth) printf 'System boot theme; needs sudo and may rebuild initramfs.' ;;
        git) printf 'Adds managed settings while preserving your Git identity.' ;;
        ssh) printf 'Adds a managed SSH fragment while preserving existing hosts.' ;;
        nvim) printf 'LazyVim config; package installation also downloads editor plugins.' ;;
        prism) printf 'Shared terminal palettes for shells, prompts and CLI tools.' ;;
        fish | bash | zsh | nushell) printf 'Shell config and integrations; login shell is chosen separately.' ;;
        waybar) printf 'Status bar, fonts and wallpaper-aware colors; included with Hyprland.' ;;
        rofi) printf 'Launcher and desktop menus; replaces an existing Rofi config.' ;;
        core-build) printf 'Compilers, Git, download tools, archives and ShellCheck.' ;;
        cpp) printf 'GCC, Clang, CMake, Ninja, Meson and debuggers.' ;;
        rust) printf 'Rust toolchain management through rustup.' ;;
        python) printf 'Python, pip and uv.' ;;
        web) printf 'Node.js, npm, pnpm and Bun.' ;;
        containers) printf 'Podman, Compose and Buildah.' ;;
        wayland) printf 'Portals, clipboard, screenshots and display utilities.' ;;
        media) printf 'PipeWire, FFmpeg, ImageMagick and yt-dlp.' ;;
        *) printf 'Installs the bundled configuration for this tool.' ;;
    esac
}

ui_select_modules() {
    local -n names_ref=$1 labels_ref=$2 categories_ref=$3 selected_ref=$4
    local title=${5:-Choose your modules}
    local cursor=0 index count=${#names_ref[@]} previous_category=''
    local rows columns start end selected_count available used cost page marker style
    local next top panel_height list_width details_x details_width row hint bar filled
    local -a initial_selection=("${selected_ref[@]}") page_starts page_ends UI_LINES=()
    while true; do
        rows=$(tput lines 2>/dev/null || printf '24')
        columns=$(tput cols 2>/dev/null || printf '80')
        if ((rows < 16 || columns < 32)); then
            ui_clear
            printf 'Resize to at least 32 x 16'
            ui_read_key || return 1
            case "$UI_KEY" in quit | escape) return 1 ;; esac
            continue
        fi
        selected_count=0
        for ((index=0; index<count; index++)); do
            [[ ${selected_ref[index]} != true ]] || ((selected_count+=1))
        done
        ui_canvas "$title" "$selected_count / $count selected  ·  CURATE YOUR WORKSPACE"
        top=$((UI_Y + 5))
        panel_height=$((UI_BOTTOM - top + 1))
        available=$((panel_height - 2))
        list_width=$UI_W
        ((UI_W < 86)) || list_width=$((UI_W * 54 / 100))
        page_starts=() page_ends=()
        start=0
        while ((start < count)); do
            used=0 end=$start previous_category=''
            while ((end < count)); do
                cost=1
                [[ ${categories_ref[end]} == "$previous_category" ]] || cost=2
                ((used + cost <= available)) || break
                used=$((used + cost))
                previous_category=${categories_ref[end]}
                ((end+=1))
            done
            page_starts+=("$start") page_ends+=("$end")
            start=$end
        done
        for ((page=0; page<${#page_starts[@]}; page++)); do
            start=${page_starts[page]} end=${page_ends[page]}
            ((cursor >= end)) || break
        done
        ui_panel "$top" "$UI_X" "$list_width" "$panel_height" 'CONFIGURATION'
        row=$((top + 1)) previous_category=''
        for ((index=start; index<end; index++)); do
            if [[ ${categories_ref[index]} != "$previous_category" ]]; then
                previous_category=${categories_ref[index]}
                ui_at "$row" "$((UI_X + 2))" "$UI_PURPLE" "$previous_category" "$((list_width - 4))"
                ((row+=1))
            fi
            marker='○' style=$UI_MUTED
            if [[ ${selected_ref[index]} == true ]]; then marker='●'; style=$UI_WHITE; fi
            if ((index == cursor)); then
                printf -v hint ' › %s %-*.*s' "$marker" "$((list_width - 9))" "$((list_width - 9))" "${labels_ref[index]}"
                ui_at "$row" "$((UI_X + 1))" "${UI_SELECTED}${UI_BOLD}" "$hint" "$((list_width - 2))"
            else
                ui_at "$row" "$((UI_X + 2))" "$style" "  $marker ${labels_ref[index]}" "$((list_width - 4))"
            fi
            ((row+=1))
        done
        if ((UI_W >= 86)); then
            details_x=$((UI_X + list_width + 2))
            details_width=$((UI_W - list_width - 2))
            ui_panel "$top" "$details_x" "$details_width" "$panel_height" 'IN FOCUS'
            ui_at "$((top + 2))" "$((details_x + 3))" "${UI_WHITE}${UI_BOLD}" "${labels_ref[cursor]}" "$((details_width - 6))"
            hint=$(ui_module_hint "${names_ref[cursor]}")
            ui_wrap "$hint" "$((details_width - 6))"
            for ((index=0; index<${#UI_LINES[@]} && index<panel_height-7; index++)); do
                ui_at "$((top + 4 + index))" "$((details_x + 3))" "$UI_MUTED" "${UI_LINES[index]}" "$((details_width - 6))"
            done
            hint='○  Not selected'
            [[ ${selected_ref[cursor]} != true ]] || hint='●  Included in your setup'
            ui_at "$((UI_BOTTOM - 2))" "$((details_x + 3))" "$UI_CYAN" "$hint" "$((details_width - 6))"
        fi
        ui_at "$UI_BOTTOM" "$((UI_X + 3))" "$UI_MUTED" " Page $((page + 1))/${#page_starts[@]} · $((start + 1))–$end of $count " "$((list_width - 6))"
        if ((columns < 60)); then
            ui_controls '↑↓ move  Space toggle  Enter' 'A all N none R reset Q exit'
        else
            ui_controls '↑↓ / j k  move     Space  toggle     Enter  continue' 'Tab category   A all   N none   R defaults   Q / Esc cancel'
        fi
        ui_read_key || return 1
        case "$UI_KEY" in
            space) [[ ${selected_ref[cursor]} == true ]] && selected_ref[cursor]=false || selected_ref[cursor]=true ;;
            all) for ((index=0; index<count; index++)); do selected_ref[index]=true; done ;;
            none) for ((index=0; index<count; index++)); do selected_ref[index]=false; done ;;
            defaults) selected_ref=("${initial_selection[@]}") ;;
            category)
                next=$((cursor + 1))
                while ((next < count)) && [[ ${categories_ref[next]} == "${categories_ref[cursor]}" ]]; do ((next+=1)); done
                ((next < count)) && cursor=$next || cursor=0
                ;;
            quit | escape) return 1 ;;
            enter) return 0 ;;
            up) ((cursor > 0)) && ((cursor--)) || true ;;
            down) ((cursor + 1 < count)) && ((cursor++)) || true ;;
            page_up) ((page > 0)) && cursor=${page_starts[page-1]} || cursor=0 ;;
            page_down) ((page + 1 < ${#page_starts[@]})) && cursor=${page_starts[page+1]} || cursor=$((count - 1)) ;;
            home) cursor=0 ;;
            end) cursor=$((count - 1)) ;;
        esac
    done
}

# Shared single-choice screen for login shells and package helpers.
ui_choose() {
    local -n result=$1 names=$2 labels=$3
    local title=$4 subtitle=$5 cursor=0 index rows columns top marker style
    for index in "${!names[@]}"; do
        [[ ${names[index]} != "$result" ]] || cursor=$index
    done
    while true; do
        rows=$(tput lines 2>/dev/null || printf '24')
        columns=$(tput cols 2>/dev/null || printf '80')
        if ((rows < 16 || columns < 32)); then
            ui_clear
            printf 'Resize to at least 32 x 16'
        else
            ui_canvas "$title" "$subtitle"
            top=$((UI_Y + 5))
            ui_panel "$top" "$UI_X" "$UI_W" "$((${#names[@]} + 2))" 'PREFERENCES'
            for index in "${!names[@]}"; do
                marker='○' style=$UI_MUTED
                [[ ${names[index]} != "$result" ]] || marker='●'
                if ((index == cursor)); then
                    style="${UI_SELECTED}${UI_BOLD}"
                    marker="› $marker"
                fi
                ui_at "$((top + 1 + index))" "$((UI_X + 2))" "$style" " $marker  ${labels[index]} " "$((UI_W - 4))"
            done
            ui_controls '↑↓ move   Enter choose' 'Q / Esc cancel'
        fi
        ui_read_key || return 1
        case "$UI_KEY" in
            quit | escape) return 1 ;;
            *) ((rows >= 16 && columns >= 32)) || continue ;;
        esac
        case "$UI_KEY" in
            enter) result=${names[cursor]}; return 0 ;;
            up) ((cursor > 0)) && ((cursor--)) || true ;;
            down) ((cursor + 1 < ${#names[@]})) && ((cursor++)) || true ;;
            home) cursor=0 ;;
            end) cursor=$((${#names[@]} - 1)) ;;
        esac
    done
}

ui_select_default_shell() {
    local -a shell_ids=(keep bash zsh fish nushell)
    local -a shell_labels=('Keep current shell' Bash Zsh Fish Nushell)
    ui_choose "$1" shell_ids shell_labels 'Default login shell' 'APPLIED AFTER SETUP  /  CHSH MAY REQUEST YOUR PASSWORD'
}

ui_select_aur_helper() {
    local -a helper_ids=(paru yay)
    local -a helper_labels=('paru · Rust-based' 'yay · Go-based')
    ui_choose "$1" helper_ids helper_labels 'AUR helper' 'FOR PACKAGES FROM THE ARCH USER REPOSITORY'
}

ui_success() {
    ui_review "$1" "${2:-INSTALLATION COMPLETE}" close || true
}

ui_failure() {
    local index top
    local -a UI_LINES=()
    ui_canvas 'Something needs attention.' 'INSTALLATION STOPPED'
    top=$((UI_Y + 5))
    ui_panel "$top" "$UI_X" "$UI_W" "$((UI_BOTTOM - top + 1))" 'DETAILS'
    ui_wrap "$1" "$((UI_W - 6))"
    for ((index=0; index<${#UI_LINES[@]} && top+1+index<UI_BOTTOM; index++)); do
        ui_at "$((top + 1 + index))" "$((UI_X + 3))" "$UI_RED" "${UI_LINES[index]}" "$((UI_W - 6))"
    done
    ui_controls 'Any key  close' 'See the terminal log for details.'
}
