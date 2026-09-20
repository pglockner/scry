# shellcheck shell=bash
# scry shared library: the handler registry plus helpers that handlers call.
# Sourced by bin/scry before any handler. Must stay compatible with bash 3.2
# (macOS's /bin/bash): no associative arrays, no mapfile, no ${var,,}.

SCRY_H_NAMES=()   # registered handler names
SCRY_H_EXTS=()    # space-separated extensions per handler, lowercase, no dot
SCRY_H_HELP=()    # one-line description per handler, shown by `scry -h`
SCRY_HELPERS=()   # helper binaries reported by `scry --doctor`
SCRY_HELPER_ENABLES=()
SCRY_HELPER_HINTS=()

# Set to 1 by `scry -f`; handlers use it to pick their "full" variant.
FORCE_WINDOW=0

# scry_register NAME "EXT EXT ..." "HELP"
#   Declare a handler. The handler must define scry_view_NAME(), which is
#   called with one file path. Extensions may be compound ("tar.gz").
#   If several handlers claim an extension, the one registered last wins,
#   so user handlers (loaded after the built-in ones) can override them.
scry_register() {
    local name="$1" exts="$2" help="$3" i
    for ((i = 0; i < ${#SCRY_H_NAMES[@]}; i++)); do
        if [ "${SCRY_H_NAMES[$i]}" = "$name" ]; then
            echo "scry: handler '$name' is registered twice; rename one" >&2
            exit 1
        fi
    done
    SCRY_H_NAMES+=("$name")
    SCRY_H_EXTS+=("$exts")
    SCRY_H_HELP+=("$help")
}

# scry_helper BIN "WHAT IT ENABLES" "INSTALL HINT"
#   Declare an external program for `scry --doctor` to check. Repeat
#   declarations of the same BIN are ignored.
scry_helper() {
    local bin="$1" i
    for ((i = 0; i < ${#SCRY_HELPERS[@]}; i++)); do
        [ "${SCRY_HELPERS[$i]}" = "$bin" ] && return 0
    done
    SCRY_HELPERS+=("$bin")
    SCRY_HELPER_ENABLES+=("$2")
    SCRY_HELPER_HINTS+=("$3")
}

# scry_find_handler FILE -- print the name of the handler that claims FILE;
# return 1 if none does.
scry_find_handler() {
    local lower i e
    lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    for ((i = ${#SCRY_H_NAMES[@]} - 1; i >= 0; i--)); do
        for e in ${SCRY_H_EXTS[$i]}; do
            case "$lower" in
                *".$e")
                    printf '%s' "${SCRY_H_NAMES[$i]}"
                    return 0
                    ;;
            esac
        done
    done
    return 1
}

# scry_require BIN HINT -- exit with an install hint if BIN is missing.
scry_require() {
    local bin="$1" hint="$2"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "scry: '$bin' not found. $hint" >&2
        exit 1
    fi
}

# Real terminal width, or empty if there's no controlling terminal. Passed
# explicitly to bat/glow since glow's own auto-detection caps at 120
# columns and misreads width when its pager pipes output internally.
# Querying /dev/tty (not `[ -t 1 ]`, which only checks our own stdout)
# gets the controlling terminal's size regardless of where stdout points.
scry_term_width() {
    local w=""
    if [ -e /dev/tty ]; then
        w="$(stty size 2>/dev/null < /dev/tty | awk '{print $2}')"
    fi
    if [ -z "$w" ] && [ -t 1 ]; then
        w="$(tput cols 2>/dev/null)" || w=""
    fi
    [ -n "${SCRY_DEBUG:-}" ] && echo "scry: detected terminal width: ${w:-<none>}" >&2
    printf '%s' "$w"
}

scry_bat_view() {
    local w
    w="$(scry_term_width)"
    if [ -n "$w" ]; then
        bat --paging=auto --terminal-width="$w" "$@"
    else
        bat --paging=auto "$@"
    fi
}

# What scry does with a file no handler claims (and with piped stdin).
scry_fallback() {
    if command -v bat >/dev/null 2>&1; then
        scry_bat_view -- "$@"
    else
        cat -- "$@"
    fi
}

# qlmanage's window doesn't activate itself, since it's launched from a
# background process -- it can open behind the focused window. Poll for
# the process and bring it forward; silently does nothing without
# Accessibility permission granted to the terminal app.
scry_qlmanage_preview() {
    local file="$1"
    scry_require qlmanage "qlmanage ships with macOS; this shouldn't happen"
    qlmanage -p "$file" >/dev/null 2>&1 &
    osascript -e '
        tell application "System Events"
            repeat 20 times
                if exists (first process whose name is "qlmanage") then
                    set frontmost of (first process whose name is "qlmanage") to true
                    exit repeat
                end if
                delay 0.05
            end repeat
        end tell
    ' >/dev/null 2>&1 &
}

# Show an image file: Quick Look window under -f, else imgcat (iTerm2) or viu.
scry_show_image() {
    local file="$1"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_qlmanage_preview "$file"
        return
    fi
    if [ "${TERM_PROGRAM:-}" = "iTerm.app" ] && command -v imgcat >/dev/null 2>&1; then
        imgcat "$file"
    else
        scry_require viu "brew install viu"
        viu "$file"
    fi
}

# bat is the fallback viewer for anything no handler claims, so it belongs
# to the core rather than to any one handler.
scry_helper bat "syntax highlighting, yaml, and the fallback viewer" "brew install bat"
