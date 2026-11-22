# shellcheck shell=bash
scry_register audio "mp3 m4a wav aiff aif aac flac caf ogg oga opus" \
    "mpv if installed, else $SCRY_AUDIO_FALLBACK_DESC (-f: mpv window with album art)"
scry_helper mpv "audio playback with progress, album-art window (-f), ogg/opus, more video" \
    "$SCRY_INSTALL mpv"

# Prefer mpv when installed: it shows a progress line and takes seek/pause
# keys. Otherwise the platform's player, which is silent.
scry_view_audio() {
    if command -v mpv >/dev/null 2>&1; then
        mpv --no-video -- "$1"
    else
        scry_play_audio "$1"
    fi
}

# mpv's defaults: a window showing embedded album art, if any.
scry_full_audio() {
    scry_require mpv
    mpv -- "$1"
}

# Never play sound from a preview; show the file's own metadata instead.
scry_preview_audio() {
    scry_info "$1"
    # mpv lists the file's tags; null outputs and --frames=0 mean nothing
    # plays and it exits right after loading.
    if command -v mpv >/dev/null 2>&1; then
        mpv --ao=null --vo=null --frames=0 --no-audio-display -- "$1" </dev/null 2>/dev/null \
            | grep -v -e '^Exiting' -e '^client removed' || true
        return
    fi
    scry_audio_info "$1"
}
