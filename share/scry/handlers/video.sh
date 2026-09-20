# shellcheck shell=bash
scry_register video "mp4 mov m4v" 'open -a "QuickTime Player"'

scry_view_video() {
    scry_require open "open ships with macOS; this shouldn't happen"
    open -a "QuickTime Player" -- "$1"
}

scry_preview_video() {
    scry_info "$1"
    mdls -name kMDItemDurationSeconds -name kMDItemPixelWidth -name kMDItemPixelHeight \
        -- "$1" 2>/dev/null | grep -v '(null)' || true
}
