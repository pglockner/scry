# shellcheck shell=bash disable=SC2154
scry_register tar "tar tgz tbz tbz2 txz tar.gz tar.bz2 tar.xz" \
    "tar -tvf (-f: extract, open in $SCRY_FOLDER_DESC)"

# No `--` before the filename below: bsdtar's -f binds to its next
# argument directly, and a literal `--` would be misparsed as the archive
# filename itself. (scry already turned a dash-leading name into ./-name.)
scry_view_tar() {
    scry_require tar "tar is part of every base system; check your PATH"
    tar -tvf "$1"
}

scry_preview_tar() {
    scry_view_tar "$1"
}

scry_extract_tar() {
    tar -xf "$1" -C "$2"
}

scry_full_tar() {
    scry_require tar "tar is part of every base system; check your PATH"
    scry_open_archive "$1" scry_extract_tar
}
