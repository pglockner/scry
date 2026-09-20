# shellcheck shell=bash disable=SC2154
scry_register zip "zip" "unzip -l (-f: extract, open in Finder)"

scry_view_zip() {
    local file="$1" tmpdir
    scry_require unzip "unzip ships with macOS; this shouldn't happen"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_require open "open ships with macOS; this shouldn't happen"
        # Doesn't clean up the temp dir: Finder needs it after this exits.
        tmpdir="$(mktemp -d)"
        unzip -q -- "$file" -d "$tmpdir"
        open -- "$tmpdir"
    else
        unzip -l -- "$file"
    fi
}

scry_preview_zip() {
    scry_require unzip "unzip ships with macOS; this shouldn't happen"
    unzip -l -- "$1"
}
