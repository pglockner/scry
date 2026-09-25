# shellcheck shell=bash disable=SC2154
scry_register zip "zip jar whl" "unzip -l (-f: extract, open in Finder)"

scry_view_zip() {
    scry_require unzip "unzip ships with macOS; this shouldn't happen"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_tmp
        unzip -q -- "$1" -d "$SCRY_TMP"
        scry_open "$SCRY_TMP"
    else
        unzip -l -- "$1"
    fi
}

scry_preview_zip() {
    scry_require unzip "unzip ships with macOS; this shouldn't happen"
    unzip -l -- "$1"
}
