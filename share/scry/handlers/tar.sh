# shellcheck shell=bash disable=SC2154
scry_register tar "tar tgz tbz tbz2 txz tar.gz tar.bz2 tar.xz" \
    "tar -tvf (-f: extract, open in Finder)"

# No `--` before the filename below: bsdtar's -f binds to its next
# argument directly, and a literal `--` would be misparsed as the archive
# filename itself. (scry already turned a dash-leading name into ./-name.)
scry_view_tar() {
    local dest
    scry_require tar "tar ships with macOS; this shouldn't happen"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_tmp
        dest="$SCRY_TMP/$(scry_stem "$1")"
        mkdir "$dest"
        tar -xf "$1" -C "$dest"
        scry_open "$dest"
    else
        tar -tvf "$1"
    fi
}

scry_preview_tar() {
    scry_require tar "tar ships with macOS; this shouldn't happen"
    tar -tvf "$1"
}
