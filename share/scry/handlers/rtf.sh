# shellcheck shell=bash
scry_register rtf "rtf" "textutil (converted to plain text)"

scry_view_rtf() {
    scry_require textutil "textutil ships with macOS; this shouldn't happen"
    textutil -convert txt -stdout -- "$1"
}
