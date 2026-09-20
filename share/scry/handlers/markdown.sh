# shellcheck shell=bash disable=SC2154
scry_register markdown "md markdown mkd mdown" "glow (-f: Quick Look window)"
scry_helper glow "markdown" "brew install glow"

scry_view_markdown() {
    local file="$1" w
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_qlmanage_preview "$file"
        return
    fi
    scry_require glow "brew install glow"
    w="$(scry_term_width)"
    if [ -n "$w" ]; then
        glow -p -w "$w" -- "$file"
    else
        glow -p -- "$file"
    fi
}
