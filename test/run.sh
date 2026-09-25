#!/usr/bin/env bash
# scry's test suite. Every helper (glow, viu, qlmanage, open, ...) is a stub
# that logs its arguments, so the tests check dispatch -- which viewer gets
# called, with what -- and run anywhere, without any helper installed.
#
#   make test                        # with the bash on PATH
#   SCRY_BASH=/bin/bash make test    # e.g. macOS's bash 3.2
# Stub bodies and handler fixtures are shell code, single-quoted on purpose.
# shellcheck disable=SC2016
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
BASH_UNDER_TEST="$(command -v "${SCRY_BASH:-bash}")" || exit 1

WORK="$(mktemp -d "${TMPDIR:-/tmp}/scry-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
STUBS="$WORK/stubs" LOG="$WORK/log" T="$WORK/tmp" F="$WORK/files"
mkdir -p "$STUBS" "$T" "$F"

# stub NAME [BODY] -- a fake helper that logs "NAME ARGS..." and runs BODY.
stub() {
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n%s\n' "$1" "$LOG" "${2:-}" > "$STUBS/$1"
    chmod +x "$STUBS/$1"
}
for b in viu vd mpv qlmanage osascript open textutil afplay mdls fzf imgcat; do
    stub "$b"
done
# Without a terminal on stdin, scry feeds glow the file on stdin.
stub glow '[ -t 0 ] || cat'
stub bat 'for a; do case "$a" in -) cat ;; -*) ;; *) cat -- "$a" ;; esac; done'
# f3d "renders" by writing a non-empty --output file.
stub f3d 'for a; do case "$a" in --output=*) echo png > "${a#--output=}" ;; esac; done'

# The system tools scry itself uses, and nothing else, so no real helper
# installed on this machine can leak into a test.
SYSBIN="$WORK/sysbin"
mkdir -p "$SYSBIN"
for b in awk basename cat column cut dirname file grep head ls mktemp pwd readlink sleep \
    rm sort stty tar touch tput tr unzip find env sh wc; do
    p="$(command -v "$b")" && ln -s "$p" "$SYSBIN/$b"
done

pass=0 fail=0
ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/    /'; }

# run ARGS... -- run scry with the stubs; sets $out (stdout+stderr), $rc.
run() {
    : > "$LOG"
    out="$(cd "$F" && env -i PATH="$STUBS:$SYSBIN" HOME="$WORK" TMPDIR="$T" \
        SCRY_USER_HANDLERS="$WORK/handlers" "$BASH_UNDER_TEST" "$ROOT/bin/scry" "$@" 2>&1 < "${STDIN:-/dev/null}")"
    rc=$?
}
expect_rc()     { if [ "$rc" -eq "$1" ]; then ok; else bad "$2: exit $rc, want $1" "$out"; fi; }
expect_out()    { case "$out" in *"$1"*) ok ;; *) bad "$2: output lacks '$1'" "$out" ;; esac; }
# Retries for a moment: Quick Look is launched in the background.
expect_called() {
    local tries=10
    while [ "$tries" -gt 0 ]; do
        if grep -qF -- "$1" "$LOG"; then ok; return; fi
        sleep 0.1
        tries=$((tries - 1))
    done
    bad "$2: no call '$1'" "$(cat "$LOG")"
}
expect_silent() { if grep -q "^$1 " "$LOG"; then bad "$2: $1 was called" "$(cat "$LOG")"; else ok; fi; }
# expect_tmp N DESC -- N temp dirs are left behind in $TMPDIR.
expect_tmp() {
    local n
    n="$(find "$T" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
    if [ "$n" = "$1" ]; then ok; else bad "$2: $n temp dirs, want $1" "$(ls -la "$T")"; fi
}

printf '# hi\n' > "$F/notes.md"
printf '# hi\n' > "$F/LOUD.MD"
printf 'a,b\n' > "$F/-dash.csv"
printf 'a,b\n1,2\n' > "$F/t.csv"
printf 'solid x\n' > "$F/part.stl"
printf 'plain text\n' > "$F/plain.txt"
printf '%%PDF-1.4\n' > "$F/doc.pdf"
: > "$F/song.ogg"
: > "$F/clip.mkv"
: > "$F/clip.mp4"
(cd "$F" && tar -cf a.tar.gz plain.txt)

# --- dispatch ---
run notes.md;           expect_called "glow -p -" "md -> glow"; expect_out "# hi" "md -> glow gets the file"
run LOUD.MD;            expect_called "glow" "extensions are case-insensitive"
run t.csv;              expect_called "vd t.csv" "csv -> visidata"
run plain.txt;          expect_out "plain text" "unclaimed -> bat"
run a.tar.gz;           expect_out "plain.txt" "tar.gz -> listing"
run song.ogg;           expect_called "mpv --no-video -- song.ogg" "audio -> mpv"
run clip.mkv;           expect_called "mpv -- clip.mkv" "mkv -> mpv"
run clip.mp4;           expect_called "open -a QuickTime Player -- clip.mp4" "mp4 -> QuickTime"
run doc.pdf;            expect_called "qlmanage -p doc.pdf" "pdf -> Quick Look"
run -f doc.pdf;         expect_called "open -a Preview -- doc.pdf" "pdf -f -> Preview"
run .;                  expect_out "notes.md" "dir -> ls"

# --- options ---
run notes.md -f;        expect_called "qlmanage -p notes.md" "option after the file"
run -fA plain.txt;      expect_called "bat --paging=auto --show-all -- plain.txt" "bundled -fA"
run -p -f notes.md;     expect_silent qlmanage "--preview overrides -f"
run -- -dash.csv;       expect_called "vd ./-dash.csv" "dash-leading name becomes ./-name"
run -z;                 expect_rc 2 "unknown option"
run -t;                 expect_rc 2 "-t without a value"
run -h;                 expect_out "model3d" "help lists handlers"
run --doctor;           expect_out "ok       glow" "doctor"
run the future;         expect_out "The mists part" "the future"

# --- -t and stdin ---
run -t md plain.txt;    expect_called "glow" "-t md on a file"; expect_out "plain text" "-t md on a file"
STDIN="$F/notes.md" run -t .MD
expect_called "glow -p -" "-t on stdin"; expect_out "# hi" "-t on stdin spools to a file"
expect_tmp 0 "spooled stdin is cleaned up"
STDIN="$F/plain.txt" run -t json
expect_called "bat --paging=auto --language=json -- -" "unclaimed -t type -> bat --language"
STDIN="$F/plain.txt" run; expect_out "plain text" "piped stdin -> bat"

# --- errors don't stop the other files, and are reported like cat ---
run nope.md notes.md
expect_rc 1 "missing file fails"
expect_out "scry: nope.md: No such file or directory" "missing file message"
expect_out "# hi" "files after a missing one are still shown"
rm "$STUBS/vd"
run t.csv notes.md
expect_out "'vd' not found" "missing helper names itself"
expect_called "glow" "files after a missing helper are still shown"
stub vd

# --- temp files ---
run part.stl
expect_called "viu" "stl -> rendered image"
expect_tmp 0 "3D render temp dir is cleaned up"
run -f part.stl
expect_called "qlmanage -p" "stl -f -> Quick Look"
expect_tmp 1 "temp dir kept for a detached window"
rm -rf "${T:?}"/*
run -p part.stl;        expect_silent qlmanage "stl preview is inline"

# --- previews never open anything ---
run -p doc.pdf song.ogg clip.mp4 notes.md
expect_silent qlmanage "pdf preview"
expect_silent open "video preview"
expect_called "glow -s dark" "md preview"
expect_out "doc.pdf" "summary preview names the file"

# --- user handlers ---
mkdir -p "$WORK/handlers"
printf 'scry_register mine "md" "mine"\nscry_view_mine() { echo "MINE $1"; }\n' \
    > "$WORK/handlers/mine.sh"
run notes.md;           expect_out "MINE notes.md" "user handler overrides a built-in"
printf 'scry_register markdown "x" "dup"\n' > "$WORK/handlers/mine.sh"
run notes.md;           expect_out "registered twice" "duplicate handler name"
printf 'scry_register strict "xx" "x"\nscry_view_strict() { false; echo "KEPT GOING"; }\n' \
    > "$WORK/handlers/mine.sh"
: > "$F/a.xx"
run a.xx notes.md
expect_rc 1 "a failing command fails the handler"
case "$out" in *"KEPT GOING"*) bad "set -e holds inside handlers" "$out" ;; *) ok ;; esac
expect_out "# hi" "and the next file is still shown"
rm -rf "$WORK/handlers"

printf '%d passed, %d failed (%s)\n' "$pass" "$fail" "$("$BASH_UNDER_TEST" -c 'echo "bash $BASH_VERSION"')"
[ "$fail" -eq 0 ]
