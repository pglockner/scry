# shellcheck shell=bash
scry_register video "mp4 mov m4v" 'open -a "QuickTime Player"'

scry_view_video() {
    scry_require open "open ships with macOS; this shouldn't happen"
    open -a "QuickTime Player" -- "$1"
}
