# shellcheck shell=bash disable=SC2154
scry_register pdf "pdf" "qlmanage window (-f: Preview.app)"

scry_view_pdf() {
    local file="$1"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_require open "open ships with macOS; this shouldn't happen"
        open -a Preview -- "$file"
    else
        scry_qlmanage_preview "$file"
    fi
}
