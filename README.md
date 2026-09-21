# scry

Like `cat`, but it picks a better viewer based on the file extension.

```
scry notes.md        # rendered markdown (glow)
scry photo.heic      # inline image (imgcat in iTerm2, viu elsewhere)
scry data.csv        # interactive table (visidata)
scry part.stl        # rendered preview of a 3D model (f3d)
scry archive.tar.gz  # archive listing
scry main.py         # syntax-highlighted (bat), or plain cat without bat
```

macOS only: it relies on `qlmanage`, `textutil`, `afplay` and `open`. Pure
bash (works with the stock macOS bash 3.2), no zsh needed.

A recognized extension whose viewer isn't installed is an error with an
install hint, never a silent fallback, so you always know why you got the
output you did.

## Install

```sh
git clone https://github.com/pglockner/scry.git && cd scry
make install          # copies to ~/.local (override: make install PREFIX=/usr/local)
make deps             # core helpers: bat, glow, viu
```

Make sure `~/.local/bin` is on your `PATH`. `make install` tells you if it isn't.
`make help` lists every target.

## Pick your helpers

Only install what you'll use. Each group is its own Brewfile:

| Command               | Installs                     | Enables                              |
| --------------------- | ---------------------------- | ------------------------------------ |
| `make deps`           | bat, glow, viu               | text/code, yaml, markdown, images    |
| `make deps-data`      | visidata                     | csv / tsv / psv                      |
| `make deps-3d`        | f3d (several hundred MB)     | stl / 3mf                            |
| `make deps-audio`     | mpv                          | audio progress, `-f` album art, ogg  |
| `make deps-fzf`       | fzf                          | `scry --fzf` file picker             |
| `make deps-quicklook` | qlmarkdown (cask)            | rendered markdown for `scry -f`      |

Or use Homebrew directly, e.g. `brew bundle --file=Brewfile.3d`.

`scry --doctor` shows which helpers are installed and what each one enables.

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

Options (any order, before the file names; use `--` before a name that starts with `-`):

| Option                | What it does                                                                     |
| --------------------- | -------------------------------------------------------------------------------- |
| `-f`, `--full`        | Use the "full" variant of the viewer (windowed / extract; see below)             |
| `-A`, `--show-all`    | Skip the handlers and show the file through `bat --show-all` (see below)         |
| `-p`, `--preview`     | Non-interactive output for previewers such as fzf (see below)                    |
| `--fzf [DIR]`         | Pick files under `DIR` (default `.`) with fzf, then view them                    |
| `--doctor`            | Show which helpers are installed and what each one enables                       |
| `-h`, `--help`        | Show usage and the table of handlers with the extensions each claims             |

### `-f`, `--full`: the full variant

`-f` means "give me the heavier, windowed view". It applies to every file on
the command line, and files with no full variant are shown normally.

| File type                        | `scry FILE`               | `scry -f FILE`                    |
| -------------------------------- | ------------------------- | --------------------------------- |
| Markdown                         | rendered in the terminal  | Quick Look window                 |
| Images                           | inline in the terminal    | Quick Look window                 |
| STL / 3MF                        | rendered image, inline    | rendered image, Quick Look window |
| PDF                              | Quick Look window         | Preview.app                       |
| Audio                            | plays (mpv, else afplay)  | mpv window with album art        |
| zip                              | file listing              | extract, open in Finder           |
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
| Images, STL / 3MF                 | block-character image at pane width (`viu`; `f3d` renders 3D) |
| CSV / TSV / PSV                   | first 30 rows as aligned columns                           |
| zip, tar, rtf                     | file listing / converted text                              |
| PDF, audio, video                 | a short summary (kind, size, pages or duration); nothing plays or opens |
| Audio, with mpv installed         | the summary plus the file's tags (artist, album, title...) |
| Anything from a handler with no preview function | a short summary, so nothing interactive ever runs in a preview pane |

`--preview` overrides `-f`, and combines with `-A`
(`fzf --preview 'scry --preview -A {}'`).

`scry --fzf` wraps all of this into a file picker: it lists the files under a
directory, sorted with the first one selected, previews each with `scry --preview`, and views what you select
(Tab to select several). Flags given before it carry over, so `scry -A --fzf`
previews and views raw. Audio picked here opens in mpv paused (if mpv is
installed), so you can see its tags before pressing space to play.

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
| `GLAMOUR_STYLE`         | Markdown style for previews (default `dark`)                     |

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
scry_helper jq "json" "brew install jq"

scry_view_json() {
    scry_require jq "brew install jq"
    jq -C . "$1" | less -R
}

# Optional: what fzf shows. No pager here, and cap the length.
scry_preview_json() {
    scry_require jq "brew install jq"
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
| `$FORCE_WINDOW`                         | `1` under `scry -f`; use it to pick a "full" variant           |
| `$SCRY_FZF`                             | `1` while viewing files picked in `scry --fzf`                 |
| `scry_info FILE`                        | Short summary (name, kind, size); a safe preview for anything  |
| `scry_show_image FILE`                  | Show an image the way scry does                                |
| `scry_preview_image_file FILE`          | Show an image as block characters at the preview-pane width    |
| `scry_bat_view ARGS...`                 | Run `bat` at the right width; honors `--preview` and `-A`      |
| `scry_term_width`                       | Print the width to render at (the fzf pane's, if previewing)   |
| `scry_qlmanage_preview FILE`            | Open a Quick Look window and bring it to the front             |

Handler names must be unique (registering the same name twice is an error).
Handlers are sourced into scry's shell, so like a `.zshrc`, only put code there
you trust. Keep them bash 3.2-compatible.

## Uninstall

```sh
make uninstall
```

This removes the `scry` command and its `share/scry` files (for a `make link`
install, just the symlink). It deliberately does **not** touch:

- **The Homebrew helpers.** `bat`, `glow`, `fzf` and the rest may be used by
  other tools. `make uninstall-deps` lists the ones that are installed and asks
  before running `brew uninstall` on them.
- **The Quick Look extension**, if you ran `make deps-quicklook`.
  `make uninstall-quicklook` unregisters it and removes the `qlmarkdown` cask.
- **Your own handlers** in `~/.config/scry/handlers/`.

## Development

```sh
make link     # run scry straight from this checkout
make lint     # shellcheck (brew install shellcheck)
```

## License

MIT
