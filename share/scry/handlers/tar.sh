# shellcheck shell=bash disable=SC2154
scry_register tar "tar tgz tbz tbz2 txz tar.gz tar.bz2 tar.xz" \
    "tar -tvf (-f: extract, open in Finder)"

# No `--` before the filename below: bsdtar's -f binds to its next
# argument directly, and a literal `--` would be misparsed as the archive
# filename itself.
scry_view_tar() {
    local file="$1" tmpdir
    scry_require tar "tar ships with macOS; this shouldn't happen"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_require open "open ships with macOS; this shouldn't happen"
        # Doesn't clean up the temp dir: Finder needs it after this exits.
        tmpdir="$(mktemp -d)"
        tar -xf "$file" -C "$tmpdir"
        open -- "$tmpdir"
    else
        tar -tvf "$file"
    fi
}
