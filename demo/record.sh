#!/bin/bash
# Record the README's demo (demo/demo.gif) in a real Ghostty window, so
# images show at full resolution through the kitty graphics protocol rather
# than as block characters. macOS only. Run from anywhere:
#
#   demo/record.sh
#
# Needs Ghostty 1.3 or later (its AppleScript drives the typing), ffmpeg, the
# helpers the demo uses (glow viu f3d vd bat fzf), and Screen Recording
# permission for the app you run this from. Quit Ghostty first: the demo
# runs its own instance with demo/ghostty.conf, and AppleScript can't tell
# two instances apart.
set -eu
cd "$(dirname "$0")"
DEMO="$PWD"
GHOSTTY=/Applications/Ghostty.app

die() { printf 'record.sh: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "macOS only (it drives Ghostty with AppleScript)"
[ -d "$GHOSTTY" ] || die "Ghostty isn't installed (brew install --cask ghostty)"
for b in ffmpeg swift glow viu f3d vd bat fzf; do
    command -v "$b" >/dev/null 2>&1 || die "$b isn't installed"
done
! pgrep -xq ghostty || die "quit Ghostty first (the demo starts its own instance)"

# --- driving the terminal ---

ghostty() { osascript -e "tell application \"Ghostty\" to $1" >/dev/null; }
pause()   { sleep "$1"; }
# key NAME [MODIFIERS] -- press a key (Ghostty's names: enter, escape, l, ...).
key()     { ghostty "send key \"$1\"${2:+ modifiers \"$2\"} to terminal 1"; }
# arrow A|B|C|D -- up, down, right, left. send key has no arrow names, so
# this sends the arrow's escape sequence (application cursor mode).
arrow()   { ghostty "perform action \"esc:O$1\" on terminal 1"; }
# type TEXT -- type it a character at a time, like a person.
type_()   {
    local s="$1" c
    while [ -n "$s" ]; do
        c="${s%"${s#?}"}" s="${s#?}"
        ghostty "input text \"$c\" to terminal 1"
        sleep 0.045
    done
}
# run COMMAND SECONDS -- type a command, press Enter, watch it for SECONDS.
run()     { type_ "$1"; pause 0.4; key enter; pause "$2"; }

# window_id -- Ghostty's on-screen window, for screencapture -l.
window_id() {
    swift - <<'EOF'
import CoreGraphics
let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
if let w = windows.first(where: { $0["kCGWindowOwnerName"] as? String == "Ghostty" }) {
    print(w["kCGWindowNumber"]!)
}
EOF
}

# --- recording ---

open -na "$GHOSTTY" --args --config-default-files=false \
    --config-file="$DEMO/ghostty.conf" --command="$DEMO/shell.sh"
wid=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    wid="$(window_id)"
    [ -z "$wid" ] || break
done
[ -n "$wid" ] || die "Ghostty's window didn't appear"
trap 'ghostty quit 2>/dev/null || true' EXIT
pause 1

mov="$(mktemp -d)/demo.mov"
screencapture -x -v -l"$wid" "$mov" &
rec=$!
pause 1

run "scry notes.md" 3.5
key l control

run "scry crystal.png" 3
key l control

run "scry knot.stl" 3.5
key l control

run "scry planets.csv" 1.5
arrow B; pause 0.3
arrow B; pause 0.3
arrow C; pause 0.3
arrow C; pause 1.5
type_ q; pause 0.3
key l control

run "scry oracle.py" 3
key l control

run "scry --fzf" 2
arrow B; pause 3.5
arrow B; pause 2
arrow B; pause 2
arrow B; pause 2.5
key escape; pause 0.5

kill -INT "$rec"
wait "$rec" || true

# screencapture -v -l includes the window's shadow; a still with -o doesn't,
# so the difference is the margin to crop. Then a GIF the README's width.
# Most of the demo is a still screen, and the capture's frames differ only
# by noise there; mpdecimate drops those (the GIF keeps each remaining frame
# on screen for as long), which makes it about a quarter of the size.
still="${mov%.mov}.png"
screencapture -x -o -l"$wid" "$still"
size() { ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$1"; }
vsize="$(size "$mov")" wsize="$(size "$still")"
mx=$(( (${vsize%x*} - ${wsize%x*}) / 2 + 2 )) my=$(( (${vsize#*x} - ${wsize#*x}) / 2 + 2 ))
crop="crop=$(( ${wsize%x*} - 4 )):$(( ${wsize#*x} - 4 )):$mx:$my"
ffmpeg -v error -y -i "$mov" -filter_complex \
    "[0:v]$crop,fps=12,mpdecimate,scale=1100:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle" \
    "$DEMO/demo.gif"
rm -rf "$(dirname "$mov")"
printf 'Wrote %s\n' "$DEMO/demo.gif"
