# scry

[![CI](https://github.com/pglockner/scry/actions/workflows/ci.yml/badge.svg)](https://github.com/pglockner/scry/actions/workflows/ci.yml)

**One command to look at any file from the terminal.** Like `cat`, but it
knows what the file is: markdown comes out rendered, images and 3D models are
drawn right in the terminal, a CSV opens as a real table, and code is
syntax-highlighted.

![scry rendering markdown, an image, a 3D model, a CSV and Python code, then browsing them all with live previews in scry --fzf](demo/demo.gif)

```
scry notes.md        # rendered markdown (glow)
scry photo.heic      # inline image (imgcat in iTerm2, viu elsewhere)
scry data.csv        # interactive table (visidata)
scry part.stl        # rendered preview of a 3D model (f3d)
scry archive.tar.gz  # archive listing
scry report.docx     # converted to plain text (textutil, or pandoc on Linux)
scry page.html       # highlighted source; scry -f page.html opens it in your browser
scry main.py         # syntax-highlighted (bat), or plain cat without bat
scry --fzf           # browse a folder with live previews of every file
curl -s URL | scry -t md   # stdin, viewed as markdown
```

- **Nothing to remember.** One command for every file; scry picks the viewer.
- **Never a mystery.** A file type whose viewer isn't installed is an error
  that says what to install, never a silent fallback. Like `cat`, one bad
  file doesn't stop the rest (scry exits 1 if any failed).
- **Install only what you use.** Every viewer is optional, and
  `scry --doctor` shows which ones you have.
- **macOS and Linux, WSL included.** Pure bash that runs on macOS's stock
  bash 3.2, so no zsh needed. It uses the system's own tools (Quick Look,
  `textutil`, `open` on macOS; `xdg-open`, `pandoc` on Linux; see
  [Linux](#linux)).
- **Easy to extend.** A new file type is a handler script of about ten lines
  ([Adding your own file types](#adding-your-own-file-types)).

## Install

```sh
git clone https://github.com/pglockner/scry.git && cd scry
./install.sh
```

The same two commands work on macOS and on Linux. The installer works out
which system it's on and handles the rest:

1. It copies scry into `~/.local` (use `--prefix DIR` to put it somewhere
   else) and, if `~/.local/bin` isn't on your `PATH`, prints the line to add
   to your shell's startup file.
2. It finds your package manager: Homebrew on macOS; apt, dnf, pacman, zypper
   or apk on Linux. Then it asks which groups of helpers you want (below).
   Groups you already have are skipped.
3. It installs them. On Linux, anything your distro doesn't package comes
   from Homebrew if you have it. Otherwise the installer lists what's still
   missing. It finishes with `scry --doctor`, which shows what's installed
   and how to get the rest.

Run it again any time to add more: `./install.sh --with fzf,3d`. Use
`./install.sh --yes` to install the recommended groups without being asked,
or `--dry-run` to see the exact commands first. `./install.sh --help` lists
every option.

| Group       | Enables                                               | macOS (Homebrew)   | Linux (your distro's packages) |
| ----------- | ----------------------------------------------------- | ------------------ | ------------------------------ |
| `core`*     | text/code, yaml, markdown, images                     | bat, glow, viu     | bat, glow, viu                 |
| `linux`*    | documents, pdf page counts, media details, opening files in their app | built into macOS | pandoc, antiword, poppler, ffmpeg, xdg-utils (wslu on WSL), file, column |
| `data`      | csv / tsv / psv                                       | visidata           | visidata                       |
| `fzf`       | `scry --fzf` file picker                              | fzf                | fzf                            |
| `3d`        | stl / 3mf / obj / ply / gltf / step                   | f3d (several hundred MB) | f3d                      |
| `audio`     | audio progress, `-f` album art, ogg, mkv / webm / avi video | mpv (over 1 GB: pulls in LLVM) | mpv          |
| `quicklook` | rendered markdown for `scry -f` (macOS only)          | qlmarkdown (cask)  | none: Linux renders with pandoc |

\* Recommended, so `--yes` installs these.

Distros don't all package everything. Debian and Ubuntu have no glow or viu,
for example. When something can't be installed, the installer says so, and
`scry --doctor` suggests other ways to get it.

### Installing by hand

If you'd rather not run the installer, `make install` copies scry into
`~/.local` (`make install PREFIX=/usr/local` puts it elsewhere). Then install
the helpers you want:

**macOS**, with [Homebrew](https://brew.sh). Each group is a Brewfile:

```sh
brew bundle --file=Brewfile            # core: bat, glow, viu
brew bundle --file=Brewfile.data       # also .fzf, .3d, .audio
```

For `quicklook`, use `./install.sh --with quicklook`, because macOS doesn't
register the cask's Quick Look extension on its own.

**Linux**, with your package manager. On Debian and Ubuntu:

```sh
sudo apt install bat fzf visidata mpv f3d pandoc antiword poppler-utils ffmpeg xdg-utils
```

Debian and Ubuntu have no packages for glow or viu. Use Homebrew
(`brew install glow viu`), or `go install github.com/charmbracelet/glow@latest`
and `cargo install viu`. Other distros mostly use the same package names
(Arch: `poppler`, `pandoc-cli`; Fedora: `ffmpeg-free`; openSUSE:
`poppler-tools`). Debian and Ubuntu name bat's command `batcat`, and scry
finds it under either name.

`scry --doctor` lists every helper scry can use, what each one enables, and
the install command for your system.

## Usage

```
scry [OPTIONS] FILE...
scry DIR
cmd | scry
```

| Invocation           | What it does                                                          |
| -------------------- | --------------------------------------------------------------------- |
| `scry FILE...`       | View each file with the viewer for its extension                      |
| `scry DIR`           | List the directory (`ls -la`)                                         |
| `cmd \| scry`        | Read piped stdin like `cat`, through `bat` if it's installed          |
| `scry -`             | The same, as a file argument (`scry a.md - b.md`)                     |

Options can go before or after the file names, and short ones combine
(`scry -fA x`, `scry notes.md -f`). Short options are case-insensitive (`-F` is
`-f`, `-a` is `-A`), so no letter will ever mean two things. Use `--` before a
name that starts with `-`.

| Option                | What it does                                                                     |
| --------------------- | -------------------------------------------------------------------------------- |
| `-f`, `--full`        | Use the "full" variant of the viewer (windowed / extract; see below)             |
| `-A`, `--show-all`    | Skip the handlers and show the file through `bat --show-all` (see below)         |
| `-e`, `--edit`        | Open the file for editing where that's easy, else view it (see below)            |
| `-p`, `--preview`     | Non-interactive output for previewers such as fzf (see below)                    |
| `-t`, `--type EXT`    | Treat every file, and stdin, as if it ended in `.EXT` (see below)                |
| `--fzf [DIR]`         | Pick files under `DIR` (default `.`) with fzf, then view them                    |
| `--doctor`            | Show which helpers are installed and what each one enables                       |
| `-h`, `--help`        | Show usage and the table of handlers with the extensions each claims             |

### `-f`, `--full`: the full variant

`-f` means "give me the heavier, windowed view". It applies to every file on
the command line, and files with no full variant are shown normally. This
table is for macOS; on Linux, every window is the file's default app instead
(see [Linux](#linux)).

| File type                        | `scry FILE`               | `scry -f FILE`                    |
| -------------------------------- | ------------------------- | --------------------------------- |
| Markdown                         | rendered in the terminal  | Quick Look window                 |
| Images                           | inline in the terminal    | Quick Look window                 |
| 3D models (stl, obj, step, ...)  | rendered image, inline    | rendered image, Quick Look window |
| PDF                              | Quick Look window         | Preview.app                       |
| HTML (html, htm, xhtml)          | highlighted source (bat)  | default browser (`open`)          |
| Audio                            | plays (mpv, else afplay)  | mpv window with album art         |
| zip, jar, whl                    | file listing              | extract, open in Finder           |
| tar, tar.gz, tar.bz2, tar.xz     | file listing              | extract, open in Finder           |

### `-e`, `--edit`: edit where it's easy

`-e` is opportunistic: a file type with an easy way to edit gets it, and
anything else is viewed as usual.

| File type                     | `scry -e FILE` opens it in               |
| ----------------------------- | ---------------------------------------- |
| csv, tsv, psv                 | visidata (edits in place; Ctrl-S saves)  |
| Markdown, YAML, HTML          | `$VISUAL`, else `$EDITOR`, else `vi`     |
| rtf, doc, docx, odt           | the default app                          |
| Unclaimed (plain text, code)  | `$VISUAL`, else `$EDITOR`, else `vi`     |
| Everything else, and stdin    | viewed, as without `-e`                  |

`-p` and `-A` override `-e`.

### Quick Look windows (macOS notes)

PDFs, and markdown, images and 3D models under `-f`, open in a Quick Look
window (`qlmanage -p`). Two macOS quirks:

- **The window may open behind your terminal.** `qlmanage` is launched from a
  background process, so it doesn't activate itself. scry brings it to the
  front with AppleScript, which needs Accessibility permission for your
  terminal app (System Settings -> Privacy & Security -> Accessibility).
  Without it the window still opens, just not focused.
- **Markdown under `-f` needs the QLMarkdown extension**
  (`./install.sh --with quicklook`, which also registers it). macOS asks you
  to approve the extension the first time it's used.

Over ssh, `-f` is ignored with a note and the file is shown in the terminal,
since a window would open on the remote machine's screen. scry only guesses
from ssh's environment variables, so a shell that has none (a herdr or tmux
server you attach to from another machine) needs `export SCRY_REMOTE=1`; use
`SCRY_REMOTE=0` to allow windows over ssh, e.g. with a forwarded display.

### `-t`, `--type`: pick the viewer yourself

For stdin, and for files whose name doesn't say what they are:

```sh
curl -s https://example.com/README.md | scry -t md   # rendered markdown
pbpaste | scry -t csv                                # clipboard in visidata
scry -t md NOTES                                     # extensionless file
scry -t json < response                              # no json handler: bat -l json
```

The leading dot is optional and case doesn't matter. When a handler claims the
type, stdin is saved to a temp file first (the viewers take a path) and removed
afterwards. When none does, the type is passed to `bat --language` instead.

### `-A`: non-printable characters

`scry -A FILE` shows tabs, spaces, line endings and other invisible characters
(`bat --show-all`). It bypasses the type-specific handlers on purpose: it's a
"what's really in this file" mode, and rendering markdown or opening a PDF
window would defeat that. It also works on stdin (`cmd | scry -A`) and needs
`bat`.

```
$ scry -A notes.txt
tab↹here··␍␊
line2␊
```

### `-p`, `--preview` and fzf

`scry --preview FILE` (or `-p`) is for previewers like fzf. It never opens a window,
pager or player, always writes to stdout, keeps color, and fits the width of
fzf's preview pane (`$FZF_PREVIEW_COLUMNS`).

```sh
fzf --preview 'scry --preview {}'
```

What each type shows:

| File type                         | Preview                                                    |
| --------------------------------- | ---------------------------------------------------------- |
| Text, code, yaml, html            | `bat` with line numbers (first 500 lines)                  |
| Markdown                          | rendered by `glow` (dark style; set `GLAMOUR_STYLE` to change) |
| Images, 3D models                 | block-character image at pane width (`viu`; `f3d` renders 3D) |
| CSV / TSV / PSV                   | first 30 rows as aligned columns                           |
| zip, tar, rtf / doc / docx / odt  | file listing / converted text                              |
| PDF, audio, video                 | a short summary (kind, size, pages or duration); nothing plays or opens |
| Audio, with mpv installed         | the summary plus the file's tags (artist, album, title...) |
| Anything from a handler with no preview function | a short summary, so nothing interactive ever runs in a preview pane |

`--preview` overrides `-f`, and combines with `-A`
(`fzf --preview 'scry --preview -A {}'`).

`scry --fzf` wraps all of this into a file picker: it lists the files under a
directory, sorted with the first one selected, previews each with
`scry --preview`, and views what you select (Tab to select several). Flags
given with it carry over, so `scry -A --fzf` previews and views raw.

```sh
scry --fzf            # files under the current directory
scry --fzf ~/Documents
```

It needs fzf (`./install.sh --with fzf`).

### Environment variables

| Variable                | Effect                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| `SCRY_DEBUG=1`          | Print the detected terminal width to stderr                      |
| `SCRY_USER_HANDLERS`    | Directory to load your own handlers from (see below)             |
| `SCRY_SHARE`            | Where to find `lib.sh` and the built-in handlers (rarely needed) |
| `SCRY_REMOTE`           | `1`: treat this shell as remote (`-f` is ignored); `0`: as local. Unset: guess from ssh |
| `SCRY_PLATFORM`         | `darwin` or `linux`: override which platform layer loads         |
| `GLAMOUR_STYLE`         | Markdown style for previews (default `dark`)                     |

## Linux

Everything works on Linux (and other Unix systems) too. In place of the
macOS tools:

| On macOS                          | On Linux                                                   |
| --------------------------------- | ---------------------------------------------------------- |
| Quick Look window, `open`, Finder | The file's default app, via `xdg-open`; folders open in your file manager |
| Quick Look markdown (`-f`)        | Rendered by `pandoc` into a web page and opened in your browser |
| `textutil` (rtf, doc, docx, odt)  | `pandoc`; `antiword` for `.doc`                            |
| `afplay` (audio without mpv)      | `ffplay`, from ffmpeg                                      |
| QuickTime Player (mp4, mov, m4v)  | `mpv`, or the default app without it                       |
| `mdls`, `afinfo` (preview details) | `pdfinfo` (poppler) for page counts, `ffprobe` (ffmpeg) for audio and video |

So under `-f`, images, 3D renders and PDFs open in whatever app your desktop
uses for that type, and archives open in your file manager. Markdown is the
exception: desktops tend to hand `.md` files to a text editor or LibreOffice,
which show the source, so scry renders it (as GitHub-flavored markdown, with
its images embedded) into a page in its temp folder and opens that in your
browser. One catch on Ubuntu, where Firefox is a snap: snaps have their own
`/tmp`, so snap Firefox can't open the page. Point scry's temp folder into
your home, e.g. `export TMPDIR="$HOME/tmp"` (the folder must exist), or use a
browser that isn't a snap.

Without a graphical session (`$DISPLAY` or `$WAYLAND_DISPLAY`), for example
over ssh, those views are an error that suggests `scry -p` instead. Videos
still go to mpv, which can sometimes play without a desktop (on a Linux
console, say); when it can't, scry says why and suggests `mpv --vo=tct` to play
the video as text in the terminal. Everything that renders in the terminal
works the same everywhere.

To install the Linux helpers, see [Install](#install): `./install.sh` picks
the packages for your distro.

**WSL (Windows):** scry runs in WSL like on any Linux, and `-f` views open in
Windows apps through `wslview` (from `wslu`, which the installer's `linux`
group installs under WSL). In Windows Terminal, viu draws images with block
characters.

## Adding your own file types

Each file type is a small handler script. The built-in ones live in
[`share/scry/handlers/`](share/scry/handlers); yours go in
`~/.config/scry/handlers/` (or `$XDG_CONFIG_HOME/scry/handlers/`, or
wherever `SCRY_USER_HANDLERS` points). Any `*.sh` file there is loaded after
the built-ins, so a handler that claims an extension already taken wins.

A handler declares itself, optionally lists the helper program it needs, and
defines one function, `scry_view_<name>`, which receives the file path. It can
also define `scry_preview_<name>` for `--preview`; without one, previews of
that type show a short summary, so a handler is never run interactively inside
a preview pane by accident.

```bash
# ~/.config/scry/handlers/json.sh
scry_register json "json jsonl" "jq, pretty-printed"
scry_helper jq "json" "$SCRY_INSTALL jq"

scry_view_json() {
    scry_require jq "$SCRY_INSTALL jq"
    jq -C . "$1" | less -R
}

# Optional: what fzf shows. No pager here, and cap the length.
scry_preview_json() {
    scry_require jq "$SCRY_INSTALL jq"
    jq -C . "$1" | head -n 200
}
```

That's it: `scry data.json` now uses it, and `scry --doctor` reports on `jq`.

What's available to handlers:

| Function / variable                     | Purpose                                                        |
| --------------------------------------- | -------------------------------------------------------------- |
| `scry_register NAME "EXTS" "HELP"`      | Claim extensions (space-separated, no dot, `tar.gz` is fine)   |
| `scry_helper BIN "ENABLES" "HINT"`      | Have `--doctor` check for `BIN`                                |
| `scry_require BIN "HINT"`               | Exit with an install hint if `BIN` is missing                  |
| `$SCRY_INSTALL`                         | This system's install command (`brew install`, `sudo apt install`, ...) |
| `scry_edit_NAME`, `scry_edit_text FILE` | Optional handler function run under `-e`; the helper opens FILE in `$VISUAL`/`$EDITOR` |
| `$FORCE_WINDOW`                         | `1` under `scry -f`; use it to pick a "full" variant           |
| `scry_tmp`, then `$SCRY_TMP`            | A private temp dir for this file, removed after its view       |
| `scry_open_extracted DIR`               | Open extracted files; a lone top-level folder opens directly   |
| `scry_open FILE [APP]`                  | Open FILE in its app (on macOS, in APP if given), keeping `$SCRY_TMP` for it |
| `scry_window FILE`                      | A viewing window: Quick Look on macOS, the default app on Linux |
| `scry_info FILE`                        | Short summary (name, kind, size); a safe preview for anything  |
| `scry_show_image FILE`                  | Show an image the way scry does                                |
| `scry_preview_image_file FILE`          | Show an image as block characters at the preview-pane width    |
| `scry_bat_view ARGS...`                 | Run `bat` (or `batcat`) at the right width; honors `--preview` and `-A` |
| `scry_term_width`                       | Print the width to render at (the fzf pane's, if previewing)   |
| `scry_lower STRING`                     | Lowercase a string (bash 3.2 has no `${var,,}`)                |
| `scry_stem FILE`                        | FILE's name without directory or extension (`a.tar.gz` -> `a`) |

Each file is viewed in a subshell of its own, so a handler may simply `exit 1`
or `return 1` on failure: that ends only this file's view, and scry moves on
to the next file. The path a handler receives never starts with `-` (scry
passes `./-name` instead), so viewers that don't take `--` are safe too.
Handlers never delete their own temp files: anything under `$SCRY_TMP` is
removed when the view ends, unless a window opened with `scry_open` or
`scry_window` may still be reading it.

Handlers stay portable by calling the platform layer instead of OS tools:
`scry_doc_to_text`, `scry_pdf_pages`, `scry_audio_info`, `scry_video_info`,
`scry_play_audio` and `scry_play_video`, along with `scry_open` and
`scry_window`. They're defined for each OS in
[`share/scry/platform/`](share/scry/platform); the header of `darwin.sh`
documents them.

Handler names must be unique (registering the same name twice is an error).
Handlers are sourced into scry's shell, so like a `.zshrc`, only put code there
you trust. Keep them bash 3.2-compatible.

## Uninstall

```sh
make uninstall
```

This removes the `scry` command and its `share/scry` files (for a `make link`
install, just the symlink). It deliberately does **not** touch:

- **The helpers.** `bat`, `glow`, `fzf` and the rest may be used by other
  tools. With Homebrew, `make uninstall-deps` lists the ones that are
  installed and asks before running `brew uninstall` on them.
- **The Quick Look extension**, if you installed the `quicklook` group.
  `make uninstall-quicklook` unregisters it and removes the `qlmarkdown` cask.
- **Your own handlers** in `~/.config/scry/handlers/`.

## Development

```sh
make link     # run scry straight from this checkout
make lint     # shellcheck (brew install shellcheck)
make test     # test suite; every helper is stubbed, so nothing needs installing
SCRY_BASH=/bin/bash make test   # ...under macOS's stock bash 3.2
vhs demo/demo.tape              # re-record the README's demo (brew install vhs)
```

The tests run both platform layers on any OS. CI runs lint on Linux, and the
tests and an install check on macOS (bash 3.2) and Linux. The demo plays the
files in [`demo/files/`](demo/files).

## License

MIT
