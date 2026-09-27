# shellcheck shell=bash
scry_register video "mp4 mov m4v mkv webm avi" "$SCRY_VIDEO_DESC"

scry_view_video() {
    scry_play_video "$1"
}

scry_preview_video() {
    scry_info "$1"
    scry_video_info "$1"
}
