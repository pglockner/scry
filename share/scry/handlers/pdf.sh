# shellcheck shell=bash disable=SC2154
scry_register pdf "pdf" "qlmanage window (-f: Preview.app)"

scry_view_pdf() {
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_open "$1" Preview
    else
        scry_qlmanage_preview "$1"
    fi
}

# The Quick Look window is for viewing, not previewing; show a summary.
scry_preview_pdf() {
    local pages
    scry_info "$1"
    pages="$(mdls -name kMDItemNumberOfPages -raw -- "$1" 2>/dev/null || true)"
    case "$pages" in ""|"(null)") ;; *) echo "$pages pages" ;; esac
}
