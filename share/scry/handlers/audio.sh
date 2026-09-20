# shellcheck shell=bash
scry_register audio "mp3 m4a wav aiff aif aac flac caf" "afplay"

scry_view_audio() {
    local file="$1"
    scry_require afplay "afplay ships with macOS; this shouldn't happen"
    # afplay doesn't support `--` as an options terminator, so a
    # dash-leading filename needs a ./ prefix instead.
    case "$file" in -*) file="./$file" ;; esac
    afplay "$file"
}

# Never play sound from a preview; show the file's own metadata instead.
scry_preview_audio() {
    scry_info "$1"
    afinfo "$1" 2>/dev/null | grep -E 'estimated duration|Data format|sample rate' || true
}
