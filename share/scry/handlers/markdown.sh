# shellcheck shell=bash disable=SC2154
scry_register markdown "md markdown mkd mdown" "glow (-f: $SCRY_WINDOW_DESC)"
scry_helper glow "markdown" "${SCRY_HINT_GLOW:-$SCRY_INSTALL glow}"

# glow ignores its file argument and reads stdin whenever stdin is a pipe
# (e.g. inside `git ls-files | while read f; do scry "$f"; done`), which
# shows a blank page. So when stdin isn't a terminal, feed it the file.
scry_view_markdown() {
    local file="$1" w args=(-p)
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_window "$file"
        return
    fi
    scry_require glow "${SCRY_HINT_GLOW:-$SCRY_INSTALL glow}"
    w="$(scry_term_width)"
    [ -n "$w" ] && args+=(-w "$w")
    if [ -t 0 ]; then
        glow "${args[@]}" -- "$file"
    else
        glow "${args[@]}" - < "$file"
    fi
}

# No pager, and an explicit style: glow only colors output on a tty otherwise.
# The file always goes in on stdin, so it doesn't matter what stdin was.
scry_preview_markdown() {
    local w args=(-s "${GLAMOUR_STYLE:-dark}")
    scry_require glow "${SCRY_HINT_GLOW:-$SCRY_INSTALL glow}"
    w="$(scry_term_width)"
    [ -n "$w" ] && args+=(-w "$w")
    glow "${args[@]}" - < "$1"
}
