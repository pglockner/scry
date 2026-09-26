# shellcheck shell=bash disable=SC2154
scry_register zip "zip jar whl" "unzip -l (-f: extract, open in $SCRY_FOLDER_DESC)"

scry_view_zip() {
    local dest
    scry_require unzip "$SCRY_INSTALL unzip"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_tmp
        dest="$SCRY_TMP/$(scry_stem "$1")"
        mkdir "$dest"
        unzip -q -- "$1" -d "$dest"
        # Resource-fork clutter from zips made with macOS's Compress.
        rm -rf "$dest/__MACOSX"
        scry_open_extracted "$dest"
    else
        unzip -l -- "$1"
    fi
}

scry_preview_zip() {
    scry_require unzip "$SCRY_INSTALL unzip"
    unzip -l -- "$1"
}
