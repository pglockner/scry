#!/usr/bin/env bash
# install.sh -- install scry and the helper programs it views files with,
# from whatever this system has: Homebrew on macOS; apt, dnf, pacman, zypper
# or apk on Linux, with Homebrew (if present) for anything the distro lacks.
#
#   ./install.sh                 install scry, then ask which helpers to add
#   ./install.sh --yes           no questions: scry and the recommended helpers
#   ./install.sh --with fzf,3d   scry and these helper groups, no questions
#   ./install.sh --no-helpers    scry only (this is what `make install` runs)
#   ./install.sh --uninstall     remove scry (this is what `make uninstall` runs)
#   ./install.sh --dry-run       show what it would run, change nothing
#
# Installs into ~/.local unless PREFIX (or --prefix) says otherwise; DESTDIR
# stages the copy, for packaging. Safe to run again: scry is replaced, and
# helpers that are already installed are skipped. Bash 3.2-compatible.
set -eu

# Relative PREFIX and DESTDIR mean the caller's directory, not the checkout.
CALLER_DIR="$PWD"
cd "$(dirname "$0")"

PREFIX="${PREFIX:-$HOME/.local}"
DESTDIR="${DESTDIR:-}"
DRY_RUN=0 YES=0 HELPERS=1 UNINSTALL=0 WITH=""

# Helper groups, in the order they're offered:
#   NAME  OS (any, darwin, linux)  RECOMMENDED (y/n)  WHAT IT ENABLES
HELPER_GROUPS='core      any    y  markdown, images, syntax highlighting (bat, glow, viu)
linux     linux  y  documents, pdf page counts, media details, opening files in apps (pandoc, poppler, ffmpeg, xdg-utils)
data      any    n  csv / tsv / psv tables (visidata)
fzf       any    n  scry --fzf, a file picker with live previews (fzf)
3d        any    n  3D model previews (f3d, several hundred MB)
audio     any    n  audio with progress, ogg, mkv / webm / avi (mpv; over 1 GB from Homebrew)
quicklook darwin n  rendered markdown in scry -f windows (QLMarkdown)'

# What a group installs from a distro's package manager: the program scry
# looks for, then the package names to try, first one found wins (names
# differ between distros). Homebrew installs a group from its Brewfile.
PACKAGES='core   bat      bat
core   glow     glow
core   viu      viu
linux  xdg-open xdg-utils
linux  file     file
linux  column   bsdextrautils util-linux
linux  pandoc   pandoc-cli pandoc
linux  antiword antiword
linux  pdfinfo  poppler-utils poppler-tools poppler
linux  ffprobe  ffmpeg ffmpeg-free
data   vd       visidata
fzf    fzf      fzf
3d     f3d      f3d
audio  mpv      mpv'

QLMD_APPEX="/Applications/QLMarkdown.app/Contents/PlugIns/Markdown QL Extension.appex"

usage() {
    cat <<EOF
Usage: ./install.sh [--yes | --with GROUPS | --no-helpers] [--dry-run] [--prefix DIR]
       ./install.sh --uninstall [--dry-run] [--prefix DIR]

Installs scry into PREFIX (default ~/.local), then the helpers it uses,
with this system's package manager.

  -y, --yes          don't ask: install the recommended helper groups
  --with GROUPS      install these groups (comma-separated, or "all"), don't ask
  --no-helpers       install scry only
  --uninstall        remove scry from PREFIX; helpers are left installed
  -n, --dry-run      print the commands, run nothing
  --prefix DIR       install scry into DIR/bin and DIR/share/scry

Helper groups on this system:
EOF
    list_groups | while read -r name _ rec desc; do
        printf '  %-10s %s%s\n' "$name" "$desc" "$([ "$rec" = y ] && echo '  [recommended]')"
    done
}

# --- output and running commands ---

say()  { printf '%s\n' "$*"; }
note() { printf '\n%s\n' "$*"; }
die()  { printf 'install.sh: %s\n' "$*" >&2; exit 2; }

# run CMD... -- show a command, then run it (only show it, under --dry-run).
run() {
    printf '  $ %s\n' "$*"
    [ "$DRY_RUN" = 1 ] || "$@"
}

# quietly CMD... -- run a command without showing it (but show it, and only
# that, under --dry-run).
quietly() {
    if [ "$DRY_RUN" = 1 ]; then printf '  $ %s\n' "$*"; else "$@"; fi
}

# ask QUESTION y|n -- yes/no from stdin, a terminal; Enter takes the default.
ask() {
    local ans hint="[y/N]"
    [ "$2" = y ] && hint="[Y/n]"
    printf '%s %s ' "$1" "$hint"
    read -r ans || ans=""
    case "$ans" in
        [yY]*) return 0 ;;
        [nN]*) return 1 ;;
        *)     [ "$2" = y ] ;;
    esac
}

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# --- this system ---

OS=linux SYSTEM=Linux
[ "$(uname -s)" != Darwin ] || { OS=darwin; SYSTEM=macOS; }
WSL=0
if [ "$OS" = linux ] && grep -qi microsoft /proc/version 2>/dev/null; then
    WSL=1 SYSTEM="Linux (WSL)"
fi

# Homebrew may be installed but not on PATH yet (a fresh shell before
# `brew shellenv`), so look where its installer puts it too.
BREW=""
for b in "$(command -v brew 2>/dev/null || true)" /opt/homebrew/bin/brew /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -n "$b" ] && [ -x "$b" ]; then BREW="$b"; break; fi
done

# The package manager to use: Homebrew on macOS; on Linux the distro's own,
# the same order scry's install hints use, then Homebrew.
PM=""
if [ "$OS" = darwin ]; then
    [ -z "$BREW" ] || PM=brew
else
    for p in apt-get dnf pacman zypper apk; do
        if command -v "$p" >/dev/null 2>&1; then PM="$p"; break; fi
    done
    [ -n "$PM" ] || [ -z "$BREW" ] || PM=brew
fi
case "$PM" in
    brew)    PM_NAME=Homebrew ;;
    apt-get) PM_NAME="apt${BREW:+ (and Homebrew)}" ;;
    *)       PM_NAME="$PM${BREW:+ (and Homebrew)}" ;;
esac

SUDO=""
if [ -n "$PM" ] && [ "$PM" != brew ] && [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
fi

# list_groups -- the HELPER_GROUPS rows for this OS.
list_groups() {
    local name os rec desc
    while read -r name os rec desc; do
        [ "$os" = any ] || [ "$os" = "$OS" ] || continue
        printf '%s %s %s %s\n' "$name" "$os" "$rec" "$desc"
    done <<EOF
$HELPER_GROUPS
EOF
}

# packages -- the PACKAGES rows; under WSL, files open in Windows apps
# through wslview, from wslu, rather than through xdg-open.
packages() {
    if [ "$WSL" = 1 ]; then
        printf '%s\n' "${PACKAGES/xdg-open xdg-utils/wslview wslu}"
    else
        printf '%s\n' "$PACKAGES"
    fi
}

# have BIN -- is BIN installed? Debian and Ubuntu name bat "batcat".
have() {
    command -v "$1" >/dev/null 2>&1 && return 0
    [ "$1" = bat ] && command -v batcat >/dev/null 2>&1
}

# missing GROUP -- print the group's programs that aren't installed.
missing() {
    local group bin _
    if [ "$1" = quicklook ]; then
        pluginkit -m 2>/dev/null | grep -q org.sbarex.QLMarkdown.QLExtension || echo QLMarkdown
        return
    fi
    while read -r group bin _; do
        [ "$group" != "$1" ] || have "$bin" || printf '%s ' "$bin"
    done <<EOF
$(packages)
EOF
}

# pm_has PM PKG -- can PM install PKG?
pm_has() {
    case "$1" in
        apt-get) apt-cache policy "$2" 2>/dev/null | grep -q 'Candidate: [^(]' ;;
        dnf)     dnf -q info "$2" >/dev/null 2>&1 ;;
        pacman)  pacman -Si "$2" >/dev/null 2>&1 ;;
        zypper)  zypper -q search -x "$2" >/dev/null 2>&1 ;;
        apk)     [ -n "$(apk search -x "$2" 2>/dev/null)" ] ;;
        brew)    "$BREW" info --formula "$2" >/dev/null 2>&1 ;;
    esac
}

# first_available PM PKG... -- print the first PKG that PM has.
first_available() {
    local pm="$1" p
    shift
    for p; do
        if pm_has "$pm" "$p"; then echo "$p"; return 0; fi
    done
    return 1
}

# pm_install PKG... -- install with the distro's package manager. Under
# --yes it doesn't ask; otherwise the package manager confirms, with sizes.
pm_install() {
    local y=""
    case "$PM" in
        apt-get) [ "$YES" = 1 ] && y=-y; run $SUDO apt-get install $y "$@" ;;
        dnf)     [ "$YES" = 1 ] && y=-y; run $SUDO dnf install $y "$@" ;;
        pacman)  [ "$YES" = 1 ] && y=--noconfirm; run $SUDO pacman -S --needed $y "$@" ;;
        zypper)  [ "$YES" = 1 ] && y=-n; run $SUDO zypper $y install "$@" ;;
        apk)     run $SUDO apk add "$@" ;;
    esac
}

# --- installing ---

install_scry() {
    local bin="$DESTDIR$PREFIX/bin" share="$DESTDIR$PREFIX/share/scry"
    # Replaces the handlers and platform dirs wholesale, so a file renamed or
    # removed in this version doesn't linger and load alongside its
    # successor. Removes bin/scry first too: after `make link` it's a symlink
    # to this checkout, and BSD install (macOS) won't copy a file onto itself.
    quietly rm -f "$bin/scry"
    quietly rm -rf "$share/handlers" "$share/platform"
    quietly install -d "$bin" "$share/handlers" "$share/platform"
    quietly install -m 755 bin/scry "$bin/scry"
    quietly install -m 644 share/scry/lib.sh "$share/lib.sh"
    quietly install -m 644 share/scry/platform/*.sh "$share/platform/"
    quietly install -m 644 share/scry/handlers/*.sh "$share/handlers/"
    say "Installed $bin/scry and $share"
}

# uninstall_scry -- remove what install_scry (or `make link`) put in PREFIX.
# Helpers are left alone: other tools may use them.
uninstall_scry() {
    local bin="$DESTDIR$PREFIX/bin" share="$DESTDIR$PREFIX/share/scry"
    quietly rm -f "$bin/scry"
    quietly rm -rf "$share"
    say "Removed $bin/scry and $share"
    say "Helpers (bat, glow, ...) and your handlers in ~/.config/scry/handlers"
    say "were left alone; see the README's Uninstall section to remove them."
}

# Homebrew: each group is a Brewfile (Brewfile for core).
install_brew() {
    local g file
    for g in $CHOSEN; do
        file=Brewfile
        [ "$g" = core ] || file="Brewfile.$g"
        run "$BREW" bundle --file="$file" || FAILED="$FAILED $g"
    done
    if in_list quicklook "$CHOSEN" && [ -n "$(missing quicklook)" ]; then
        # macOS doesn't register this cask's Quick Look extension by itself.
        run pluginkit -a "$QLMD_APPEX"
        quietly qlmanage -r >/dev/null 2>&1 || true
        quietly qlmanage -r cache >/dev/null 2>&1 || true
    fi
}

# A distro's package manager: the missing programs of each group, by the
# first package name it has; programs it lacks come from Homebrew if that's
# installed, and are reported otherwise.
install_native() {
    local group bin pkgs pkg need="" native="" brewed="" none=""
    while read -r group bin pkgs; do
        in_list "$group" "$CHOSEN" && ! have "$bin" && need="$need$bin $pkgs
"
    done <<EOF
$(packages)
EOF
    [ -n "$need" ] || return 0
    if [ "$PM" = apt-get ]; then
        run $SUDO apt-get update -qq || true   # fresh systems have no package lists
    fi
    while read -r bin pkgs; do
        [ -n "$bin" ] || continue
        # shellcheck disable=SC2086  # package names, split on purpose
        if pkg="$(first_available "$PM" $pkgs)"; then
            native="$native $pkg"
        elif [ -n "$BREW" ] && pkg="$(first_available brew $pkgs)"; then
            brewed="$brewed $pkg"
        else
            none="$none $bin"
        fi
    done <<EOF
$need
EOF
    # shellcheck disable=SC2086
    [ -z "$native" ] || pm_install $native || FAILED="$FAILED$native"
    # shellcheck disable=SC2086
    [ -z "$brewed" ] || run "$BREW" install $brewed || FAILED="$FAILED$brewed"
    [ -z "$none" ] || UNAVAILABLE="$none"
}

# parse_with -- turn --with's list into CHOSEN, or fail on a name that
# isn't a group for this system.
parse_with() {
    local name here="" every="" _
    while read -r name _; do every="$every $name"; done <<< "$HELPER_GROUPS"
    while read -r name _; do here="$here $name"; done <<< "$(list_groups)"
    [ "$WITH" = all ] && WITH="$here"
    for name in $(printf '%s' "$WITH" | tr ',' ' '); do
        in_list "$name" "$here" && { CHOSEN="$CHOSEN $name"; continue; }
        in_list "$name" "$every" && die "the $name helpers aren't for $SYSTEM"
        die "no helper group '$name' (see ./install.sh --help)"
    done
}

# choose_groups -- set CHOSEN to the recommended groups under --yes, or else
# the ones the user says yes to. Groups already installed are left out.
choose_groups() {
    local name rec desc _
    [ "$YES" = 1 ] || note "Which helpers? All optional: scry says when a file type needs one."
    # The rows come in on fd 3, so that stdin stays the terminal for ask.
    while read -r name _ rec desc <&3; do
        if [ -z "$(missing "$name")" ]; then
            [ "$YES" = 1 ] || printf '  %-10s %s: installed\n' "$name" "$desc"
        elif [ "$YES" = 0 ]; then
            if ask "$(printf '  %-10s %s' "$name" "$desc")" "$rec"; then CHOSEN="$CHOSEN $name"; fi
        elif [ "$rec" = y ]; then
            CHOSEN="$CHOSEN $name"
        fi
    done 3<<< "$(list_groups)"
}

path_note() {
    local rc
    case ":$PATH:" in *":$PREFIX/bin:"*) return ;; esac
    # shellcheck disable=SC2088  # shown to the user, not expanded here
    case "${SHELL##*/}" in
        fish) note "$PREFIX/bin isn't on your PATH. To add it: fish_add_path $PREFIX/bin"; return ;;
        zsh)  rc="~/.zshrc" ;;
        bash) rc="~/.bashrc"; [ "$OS" = linux ] || rc="~/.bash_profile" ;;
        *)    rc="~/.profile" ;;
    esac
    note "$PREFIX/bin isn't on your PATH. To add it, run this and open a new terminal:"
    say "  echo 'export PATH=\"$PREFIX/bin:\$PATH\"' >> $rc"
}

# --- main ---

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)     YES=1 ;;
        --with)       [ $# -ge 2 ] || die "--with needs a list of groups"; WITH="$2"; shift ;;
        --with=*)     WITH="${1#--with=}" ;;
        --no-helpers) HELPERS=0 ;;
        --uninstall)  UNINSTALL=1 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        --prefix)     [ $# -ge 2 ] || die "--prefix needs a directory"; PREFIX="$2"; shift ;;
        --prefix=*)   PREFIX="${1#--prefix=}" ;;
        -h|--help)    usage; exit 0 ;;
        *)            die "unknown option '$1' (see ./install.sh --help)" ;;
    esac
    shift
done
# Nobody to ask (--with, or not run from a terminal): the package manager
# mustn't ask either.
if [ -n "$WITH" ] || [ ! -t 0 ]; then YES=1; fi
CHOSEN="" FAILED="" UNAVAILABLE=""
[ -z "$WITH" ] || parse_with
case "$PREFIX" in /*) ;; *) PREFIX="$CALLER_DIR/$PREFIX" ;; esac
case "$DESTDIR" in /*|"") ;; *) DESTDIR="$CALLER_DIR/$DESTDIR" ;; esac

if [ "$UNINSTALL" = 1 ]; then
    uninstall_scry
    exit 0
fi

if [ "$HELPERS" = 0 ]; then
    install_scry
    path_note
    exit 0
fi

if [ -z "$PM" ]; then
    say "scry installer: $SYSTEM"
else
    say "scry installer: $SYSTEM, helpers from $PM_NAME"
fi
[ "$DRY_RUN" = 0 ] || say "Dry run: showing what would run, changing nothing."
echo
install_scry

if [ -z "$PM" ]; then
    if [ "$OS" = darwin ]; then
        note "scry's helpers come from Homebrew, which isn't installed. Get it from"
        say "https://brew.sh, then run ./install.sh again."
    else
        note "No package manager scry knows (apt, dnf, pacman, zypper, apk, Homebrew)."
        say "Install the helpers yourself: scry --doctor lists them."
    fi
elif [ "$PM" != brew ] && [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ]; then
    note "Installing helpers with $PM_NAME needs root, and sudo isn't installed:"
    say "run ./install.sh as root, or install them yourself (scry --doctor lists them)."
else
    [ -n "$WITH" ] || choose_groups
    if [ -n "$CHOSEN" ]; then
        note "Installing helpers:$CHOSEN"
        if [ "$PM" = brew ]; then install_brew; else install_native; fi
    fi
fi

[ -z "$UNAVAILABLE" ] || note "Not packaged for $PM_NAME:$UNAVAILABLE (see below for other ways to get them)"
[ -z "$FAILED" ] || note "Not installed (the package manager failed, or you declined):$FAILED"

# What's installed now; in a dry run, from this checkout.
if [ -z "$DESTDIR" ]; then
    echo
    if [ "$DRY_RUN" = 1 ]; then bin/scry --doctor; else "$PREFIX/bin/scry" --doctor; fi
fi
path_note
note "Try it: scry README.md, or scry --fzf to browse with previews."
