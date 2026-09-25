# shellcheck shell=bash disable=SC2034  # read by lib.sh, the handlers and bin/scry
# scry platform layer: Linux, and any other non-macOS Unix, including WSL.
# Sourced by lib.sh; defines what darwin.sh documents, with freedesktop and
# cross-platform tools in place of the macOS ones:
#
#   macOS               here
#   open, qlmanage      xdg-open (wslview under WSL)
#   textutil            pandoc; antiword for .doc
#   mdls, afinfo        pdfinfo (poppler), ffprobe (ffmpeg)
#   afplay              ffplay (ffmpeg), when mpv isn't installed
#
# Must stay compatible with bash 3.2 (the tests run it on macOS, too).

# The distro's package manager, for install hints. Package names are the
# common ones; poppler's tools are split out under another name on some.
# Debian and Ubuntu don't package glow or viu, so their hints name other
# ways to get them.
SCRY_POPPLER=poppler-utils
if command -v apt-get >/dev/null 2>&1; then
    SCRY_INSTALL="sudo apt install"
    SCRY_HINT_GLOW="brew install glow, or: go install github.com/charmbracelet/glow@latest"
    SCRY_HINT_VIU="brew install viu, or: cargo install viu"
elif command -v dnf >/dev/null 2>&1; then
    SCRY_INSTALL="sudo dnf install"
elif command -v pacman >/dev/null 2>&1; then
    SCRY_INSTALL="sudo pacman -S"
    SCRY_POPPLER=poppler
elif command -v zypper >/dev/null 2>&1; then
    SCRY_INSTALL="sudo zypper install"
elif command -v apk >/dev/null 2>&1; then
    SCRY_INSTALL="sudo apk add"
elif command -v brew >/dev/null 2>&1; then
    SCRY_INSTALL="brew install"
    SCRY_POPPLER=poppler
else
    SCRY_INSTALL="install"
fi
SCRY_DOCTOR_NOTE="Not packaged by your distro? Homebrew runs on Linux and has them all: make deps"
SCRY_WINDOW_DESC="default app"
SCRY_FOLDER_DESC="file manager"
SCRY_PDF_DESC="default PDF app"
SCRY_VIDEO_DESC="mpv, else the default app"
SCRY_AUDIO_FALLBACK_DESC="ffplay"
SCRY_DOC_DESC="pandoc (antiword for .doc), as plain text"

# WSL opens files in their Windows apps with wslview (from wslu); elsewhere,
# xdg-open.
SCRY_OPENER=xdg-open
SCRY_OPENER_PKG=xdg-utils
if command -v wslview >/dev/null 2>&1; then
    SCRY_OPENER=wslview
    SCRY_OPENER_PKG=wslu
fi

scry_platform_open() {
    # Name the file the user asked for, not a temp file made from it.
    local what="${SCRY_FILE:-$1}"
    if [ "$SCRY_OPENER" = xdg-open ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        echo "scry: no graphical session to open '$what' in (try: scry -p '$what')" >&2
        exit 1
    fi
    scry_require "$SCRY_OPENER" "$SCRY_INSTALL $SCRY_OPENER_PKG"
    # Backgrounded: without a desktop environment, xdg-open can run the app
    # in the foreground and wait for it. The APP argument names a macOS app,
    # so it's ignored; the file opens in the user's default app for its type.
    "$SCRY_OPENER" "$1" >/dev/null 2>&1 &
}

# No Quick Look here; the default app is the closest thing.
scry_window() {
    scry_open "$1"
}

scry_doc_to_text() {
    case "$(scry_lower "$1")" in
        *.doc)
            scry_require antiword "$SCRY_INSTALL antiword  (pandoc can't read .doc)"
            antiword "$1"
            ;;
        *)
            scry_require pandoc "$SCRY_INSTALL pandoc"
            pandoc --to=plain --wrap=none "$1"
            ;;
    esac
}

scry_pdf_pages() {
    command -v pdfinfo >/dev/null 2>&1 || return 0
    pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ { print $2 }'
}

# ffprobe knows audio and video alike; without it, previews show just the
# summary line.
scry_media_info() {
    command -v ffprobe >/dev/null 2>&1 || return 0
    ffprobe -v error -of default=noprint_wrappers=1 \
        -show_entries format=duration:stream=codec_name,width,height,sample_rate,channels \
        "$1" 2>/dev/null || true
}

scry_audio_info() {
    scry_media_info "$1"
}

scry_video_info() {
    scry_media_info "$1"
}

scry_play_audio() {
    if command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit -loglevel error "$1"
    else
        scry_require mpv "$SCRY_INSTALL mpv"
    fi
}

scry_play_video() {
    if command -v mpv >/dev/null 2>&1; then
        mpv -- "$1"
    else
        scry_open "$1"
    fi
}

scry_platform_helpers() {
    scry_helper "$SCRY_OPENER" "opening files in their app (-f, pdf, video without mpv)" \
        "$SCRY_INSTALL $SCRY_OPENER_PKG"
    scry_helper pandoc "rtf/docx/odt as text" "$SCRY_INSTALL pandoc"
    scry_helper antiword ".doc as text" "$SCRY_INSTALL antiword"
    scry_helper pdfinfo "page counts in pdf previews" "$SCRY_INSTALL $SCRY_POPPLER"
    scry_helper ffprobe "audio/video details in previews; ffplay plays audio without mpv" \
        "$SCRY_INSTALL ffmpeg"
}
