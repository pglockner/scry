# shellcheck shell=bash disable=SC2154
scry_register zip "zip jar whl" "unzip -l (-f: extract, open in $SCRY_FOLDER_DESC)"
scry_helper unzip "zip/jar/whl" "$SCRY_INSTALL unzip"

scry_view_zip() {
    scry_require unzip
    unzip -l -- "$1"
}

scry_preview_zip() {
    scry_view_zip "$1"
}

scry_extract_zip() {
    unzip -q -- "$1" -d "$2"
}

scry_full_zip() {
    scry_require unzip
    scry_open_archive "$1" scry_extract_zip
}
