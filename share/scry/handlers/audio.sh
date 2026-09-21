# shellcheck shell=bash
scry_register audio "mp3 m4a wav aiff aif aac flac caf ogg oga opus" "mpv if installed, else afplay (-f: mpv window with album art)"
scry_helper mpv "audio playback with progress, album-art window (-f), ogg/opus" "brew install mpv"

scry_view_audio() {
    local file="$1"
    if [ "$FORCE_WINDOW" = "1" ]; then
        scry_require mpv "brew install mpv (or: make deps-audio)"
        # mpv's defaults: a window showing embedded album art, if any.
        mpv -- "$file"
        return
    fi
    # Prefer mpv when installed: it shows a progress line and takes
    # seek/pause keys. Otherwise fall back to afplay, which is silent.
    if command -v mpv >/dev/null 2>&1; then
        # Picked from `scry --fzf`: start paused, so the tags and status
        # line are visible before anything plays (space to start).
        local pause=()
        [ "$SCRY_FZF" = "1" ] && pause=(--pause)
        mpv --no-video "${pause[@]}" -- "$file"
        return
    fi
    # afplay can't decode Ogg containers.
    case "$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')" in
        *.ogg|*.oga|*.opus)
            echo "scry: afplay can't play Ogg; brew install mpv (or: make deps-audio)" >&2
            exit 1
            ;;
    esac
    scry_require afplay "afplay ships with macOS; this shouldn't happen"
    # afplay doesn't support `--` as an options terminator, so a
    # dash-leading filename needs a ./ prefix instead.
    case "$file" in -*) file="./$file" ;; esac
    afplay "$file"
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
    afinfo "$1" 2>/dev/null | grep -E 'estimated duration|Data format|sample rate' || true
}
