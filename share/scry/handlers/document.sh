# shellcheck shell=bash
scry_register document "rtf doc docx odt" "textutil (converted to plain text)"

scry_view_document() {
    scry_require textutil "textutil ships with macOS; this shouldn't happen"
    textutil -convert txt -stdout -- "$1"
}

scry_preview_document() {
    scry_view_document "$1" | head -n 200
}
