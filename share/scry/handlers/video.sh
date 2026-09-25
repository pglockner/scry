# shellcheck shell=bash
scry_register video "mp4 mov m4v mkv webm avi" \
    'open -a "QuickTime Player" (mkv, webm, avi: mpv)'

scry_view_video() {
    case "$(scry_lower "$1")" in
        *.mp4|*.mov|*.m4v) scry_open "$1" "QuickTime Player" ;;
        *)
            scry_require mpv "brew install mpv (QuickTime can't play this format)"
            mpv -- "$1"
            ;;
    esac
}

scry_preview_video() {
    scry_info "$1"
    mdls -name kMDItemDurationSeconds -name kMDItemPixelWidth -name kMDItemPixelHeight \
        -- "$1" 2>/dev/null | grep -v '(null)' || true
}
