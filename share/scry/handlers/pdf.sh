# shellcheck shell=bash disable=SC2154
scry_register pdf "pdf" "$SCRY_PDF_DESC"

scry_view_pdf() {
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_open "$1" Preview   # the app is macOS's; elsewhere, the default app
    else
        scry_window "$1"
    fi
}

# The window is for viewing, not previewing; show a summary.
scry_preview_pdf() {
    local pages
    scry_info "$1"
    pages="$(scry_pdf_pages "$1")"
    [ -z "$pages" ] || echo "$pages pages"
}
