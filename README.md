# scry

Like `cat`, but it picks a better viewer based on the file extension.

```
scry notes.md        # rendered markdown (glow)
scry photo.heic      # inline image (imgcat in iTerm2, viu elsewhere)
scry data.csv        # interactive table (visidata)
scry part.stl        # rendered preview of a 3D model (f3d)
scry archive.tar.gz  # archive listing
scry report.docx     # converted to plain text (textutil, or pandoc on Linux)
scry main.py         # syntax-highlighted (bat), or plain cat without bat
curl -s URL | scry -t md   # stdin, viewed as markdown
```

Runs on macOS and Linux, including WSL on Windows. It's pure bash (it
works with macOS's stock bash 3.2), so no zsh is needed. On macOS it uses
the system's own tools (Quick Look, `textutil`, `afplay`, `open`); on Linux,
their usual counterparts (see [Linux](#linux)).

A recognized extension whose viewer isn't installed is an error with an
install hint, never a silent fallback, so you always know why you got the
output you did. Like `cat`, an error on one file (missing file, missing
viewer) doesn't stop the others; scry exits 1 if any of them failed.

## Install

```sh
git clone https://github.com/pglockner/scry.git && cd scry
make install          # copies to ~/.local (override: make install PREFIX=/usr/local)
make deps             # core helpers: bat, glow, viu (Homebrew)
```

Make sure `~/.local/bin` is on your `PATH`. `make install` tells you if it isn't.
`make help` lists every target. On Linux, you can use your distro's packages
instead of Homebrew: see [Linux](#linux).

## Pick your helpers

Only install what you'll use. Each group is its own Brewfile (Homebrew runs
on Linux too):

| Command               | Installs                     | Enables                              |
| --------------------- | ---------------------------- | ------------------------------------ |
| `make deps`           | bat, glow, viu               | text/code, yaml, markdown, images    |
| `make deps-data`      | visidata                     | csv / tsv / psv                      |
| `make deps-3d`        | f3d (several hundred MB)     | stl / 3mf / obj / ply / gltf / step  |
| `make deps-audio`     | mpv                          | audio progress, `-f` album art, ogg, mkv / webm / avi video |
| `make deps-fzf`       | fzf                          | `scry --fzf` file picker             |
| `make deps-linux`     | pandoc, antiword, poppler, ffmpeg | Linux only: documents, pdf page counts, media details, audio without mpv |
| `make deps-quicklook` | qlmarkdown (cask)            | macOS only: rendered markdown for `scry -f` |

Or use Homebrew directly, e.g. `brew bundle --file=Brewfile.3d`.

`scry --doctor` shows which helpers are installed, what each one enables,
and how to install the missing ones on your system.

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
(`scry -fA x`, `scry notes.md -f`). Use `--` before a name that starts with `-`.

| Option                | What it does                                                                     |
| --------------------- | -------------------------------------------------------------------------------- |
| `-f`, `--full`        | Use the "full" variant of the viewer (windowed / extract; see below)             |
| `-A`, `--show-all`    | Skip the handlers and show the file through `bat --show-all` (see below)         |
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
| Audio                            | plays (mpv, else afplay)  | mpv window with album art         |
| zip, jar, whl                    | file listing              | extract, open in Finder           |
| tar, tar.gz, tar.bz2, tar.xz     | file listing              | extract, open in Finder           |

### Quick Look windows (macOS notes)

PDFs, and markdown, images and 3D models under `-f`, open in a Quick Look
window (`qlmanage -p`). Two macOS quirks:

- **The window may open behind your terminal.** `qlmanage` is launched from a
  background process, so it doesn't activate itself. scry brings it to the
  front with AppleScript, which needs Accessibility permission for your
  terminal app (System Settings -> Privacy & Security -> Accessibility).
  Without it the window still opens, just not focused.
- **Markdown under `-f` needs the QLMarkdown extension** (`make deps-quicklook`,
  which also registers it). macOS asks you to approve the extension the first
  time it's used.

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
| Text, code, yaml                  | `bat` with line numbers (first 500 lines)                  |
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
directory, sorted with the first one selected, previews each with `scry --preview`, and views what you select
(Tab to select several). Flags given with it carry over, so `scry -A --fzf`
previews and views raw.

```sh
scry --fzf            # files under the current directory
scry --fzf ~/Documents
```

It needs `make deps-fzf`.

### Environment variables

| Variable                | Effect                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| `SCRY_DEBUG=1`          | Print the detected terminal width to stderr                      |
| `SCRY_USER_HANDLERS`    | Directory to load your own handlers from (see below)             |
| `SCRY_SHARE`            | Where to find `lib.sh` and the built-in handlers (rarely needed) |
| `SCRY_PLATFORM`         | `darwin` or `linux`: override which platform layer loads         |
| `GLAMOUR_STYLE`         | Markdown style for previews (default `dark`)                     |

## Linux

Everything works on Linux (and other Unix systems) too. In place of the
macOS tools:

| On macOS                          | On Linux                                                   |
| --------------------------------- | ---------------------------------------------------------- |
| Quick Look window, `open`, Finder | The file's default app, via `xdg-open`; folders open in your file manager |
| `textutil` (rtf, doc, docx, odt)  | `pandoc`; `antiword` for `.doc`                            |
| `afplay` (audio without mpv)      | `ffplay`, from ffmpeg                                      |
| QuickTime Player (mp4, mov, m4v)  | `mpv`, or the default app without it                       |
| `mdls`, `afinfo` (preview details) | `pdfinfo` (poppler) for page counts, `ffprobe` (ffmpeg) for audio and video |

So under `-f`, markdown, images, 3D renders and PDFs open in whatever app your
desktop uses for that type, and archives open in your file manager. Without a
graphical session (`$DISPLAY` or `$WAYLAND_DISPLAY`), for example over ssh,
those views are an error that suggests `scry -p` instead. Everything that
renders in the terminal works the same everywhere.

Install the helpers with your package manager. On Debian and Ubuntu:

```sh
sudo apt install bat fzf visidata mpv f3d pandoc antiword poppler-utils ffmpeg xdg-utils
```

Debian and Ubuntu package bat as `batcat`; scry finds it under either name.
They don't package glow or viu: use Homebrew (`brew install glow viu`), or
`go install github.com/charmbracelet/glow@latest` and `cargo install viu`.
Other distros' names are mostly the same (`poppler` instead of
`poppler-utils` on Arch). `scry --doctor` gives install commands for your
package manager.

**WSL (Windows):** scry runs in WSL like on any Linux, and `-f` views open in
Windows apps when `wslview` is installed (`sudo apt install wslu`). In
Windows Terminal, viu draws images with block characters.

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
| `$FORCE_WINDOW`                         | `1` under `scry -f`; use it to pick a "full" variant           |
| `scry_tmp`, then `$SCRY_TMP`            | A private temp dir for this file, removed after its view       |
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
`scry_window` may still be reading it. (`scry_qlmanage_preview`, the old name
of `scry_window`, still works.)

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
- **The Quick Look extension**, if you ran `make deps-quicklook`.
  `make uninstall-quicklook` unregisters it and removes the `qlmarkdown` cask.
- **Your own handlers** in `~/.config/scry/handlers/`.

## Development

```sh
make link     # run scry straight from this checkout
make lint     # shellcheck (brew install shellcheck)
make test     # test suite; every helper is stubbed, so nothing needs installing
SCRY_BASH=/bin/bash make test   # ...under macOS's stock bash 3.2
```

The tests run both platform layers on any OS. CI runs lint on Linux, and the
tests and an install check on macOS (bash 3.2) and Linux.

## License

MIT
