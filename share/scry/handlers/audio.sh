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
