# shellcheck shell=bash
scry_register html "html htm xhtml" "bat, as source (-f: default browser)"

# The terminal shows the source; -f hands the page to the default app for
# .html, which is the browser. A spooled stdin page stays readable after
# scry exits, since scry_open keeps the temp dir.
scry_view_html() {
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_open "$1"
    else
        scry_fallback "$1"
    fi
}

scry_preview_html() {
    scry_fallback "$1"
}

scry_edit_html() {
    scry_edit_text "$1"
}
