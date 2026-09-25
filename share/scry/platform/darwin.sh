# shellcheck shell=bash disable=SC2034  # read by lib.sh, the handlers and bin/scry
# scry platform layer: macOS. Sourced by lib.sh when `uname -s` is Darwin.
# Every platform file defines the same things (see linux.sh for the other):
#
#   SCRY_INSTALL             install-command prefix for hints ("brew install")
#   SCRY_DOCTOR_NOTE         extra line for `scry --doctor`, or empty
#   SCRY_*_DESC              what this platform uses, for `scry -h`
#   SCRY_HINT_GLOW, _VIU     optional: hints for when SCRY_INSTALL can't get them
#   scry_platform_open FILE [APP]  open FILE in its app (or in APP); detached
#   scry_window FILE         a quick viewing window for FILE; detached
#   scry_doc_to_text FILE    print an rtf/doc/docx/odt file as plain text
#   scry_pdf_pages FILE      print the page count, or nothing if unknown
#   scry_audio_info FILE     print a few lines about an audio file (may be empty)
#   scry_video_info FILE     the same for a video file
#   scry_play_audio FILE     play audio when mpv isn't installed
#   scry_play_video FILE     play a video
#   scry_platform_helpers    declare this platform's helpers for --doctor
#
# Handlers call these instead of any OS-specific tool. Must stay compatible
# with bash 3.2.

SCRY_INSTALL="brew install"
SCRY_DOCTOR_NOTE="Bundled with macOS (not checked): qlmanage, textutil, unzip, tar, afplay, afinfo, mdls, open"
SCRY_WINDOW_DESC="Quick Look window"
SCRY_FOLDER_DESC="Finder"
SCRY_PDF_DESC="Quick Look window (-f: Preview.app)"
SCRY_VIDEO_DESC="QuickTime Player (mkv, webm, avi: mpv)"
SCRY_AUDIO_FALLBACK_DESC="afplay"
SCRY_DOC_DESC="textutil, as plain text"

# Everything used here ships with macOS; SCRY_DOCTOR_NOTE lists it instead.
scry_platform_helpers() {
    :
}

scry_platform_open() {
    scry_require open "open ships with macOS; this shouldn't happen"
    if [ -n "${2:-}" ]; then
        open -a "$2" -- "$1"
    else
        open -- "$1"
    fi
}

# A Quick Look window. qlmanage's window doesn't activate itself, since it's
# launched from a background process -- it can open behind the focused
# window. Poll for the process and bring it forward; silently does nothing
# without Accessibility permission granted to the terminal app.
scry_window() {
    scry_require qlmanage "qlmanage ships with macOS; this shouldn't happen"
    SCRY_DETACHED=1
    qlmanage -p "$1" >/dev/null 2>&1 &
    osascript -e '
        tell application "System Events"
            repeat 20 times
                if exists (first process whose name is "qlmanage") then
                    set frontmost of (first process whose name is "qlmanage") to true
                    exit repeat
                end if
                delay 0.05
            end repeat
        end tell
    ' >/dev/null 2>&1 &
}

scry_doc_to_text() {
    scry_require textutil "textutil ships with macOS; this shouldn't happen"
    textutil -convert txt -stdout -- "$1"
}

scry_pdf_pages() {
    local pages
    pages="$(mdls -name kMDItemNumberOfPages -raw -- "$1" 2>/dev/null || true)"
    case "$pages" in ""|"(null)") ;; *) printf '%s\n' "$pages" ;; esac
}

scry_audio_info() {
    afinfo "$1" 2>/dev/null | grep -E 'estimated duration|Data format|sample rate' || true
}

scry_video_info() {
    mdls -name kMDItemDurationSeconds -name kMDItemPixelWidth -name kMDItemPixelHeight \
        -- "$1" 2>/dev/null | grep -v '(null)' || true
}

scry_play_audio() {
    # afplay can't decode Ogg containers.
    case "$(scry_lower "$1")" in
        *.ogg|*.oga|*.opus)
            echo "scry: afplay can't play Ogg; $SCRY_INSTALL mpv (or: make deps-audio)" >&2
            exit 1
            ;;
    esac
    scry_require afplay "afplay ships with macOS; this shouldn't happen"
    # afplay doesn't take `--`; scry already made a dash-leading name ./-name.
    afplay "$1"
}

# QuickTime for what it plays, mpv for the rest.
scry_play_video() {
    case "$(scry_lower "$1")" in
        *.mp4|*.mov|*.m4v) scry_open "$1" "QuickTime Player" ;;
        *)
            scry_require mpv "$SCRY_INSTALL mpv (QuickTime can't play this format)"
            mpv -- "$1"
            ;;
    esac
}
