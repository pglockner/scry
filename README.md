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
git clone <this repo> && cd scry
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
| `make deps-quicklook` | qlmarkdown (cask)            | rendered markdown for `scry -f`      |

Or use Homebrew directly, e.g. `brew bundle --file=Brewfile.3d`.

`scry --doctor` shows which helpers are installed and what each one enables.

## Usage

```
scry [-f] FILE...
scry DIR
cmd | scry
scry --doctor
scry -h | --help
```

| Invocation         | What it does                                                          |
| ------------------ | --------------------------------------------------------------------- |
| `scry FILE...`     | View each file with the viewer for its extension                      |
| `scry -f FILE...`  | Use the "full" variant of the viewer (see below)                      |
| `scry DIR`         | List the directory (`ls -la`)                                         |
| `cmd \| scry`      | Read piped stdin like `cat`, through `bat` if it's installed          |
| `scry --doctor`    | Show which helpers are installed and what each one enables            |
| `scry -h`, `--help`| Show usage and the table of handlers with the extensions each claims  |

`-f` must come first, before the file names, and applies to all of them. It
means "give me the heavier, windowed view". Files with no full variant are
shown normally.

| File type                        | `scry FILE`               | `scry -f FILE`                   |
| -------------------------------- | ------------------------- | -------------------------------- |
| Markdown                         | rendered in the terminal  | Quick Look window                |
| Images                           | inline in the terminal    | Quick Look window                |
| STL / 3MF                        | rendered image, inline    | rendered image, Quick Look window |
| PDF                              | Quick Look window         | Preview.app                      |
| zip                              | file listing              | extract, open in Finder          |
| tar, tar.gz, tar.bz2, tar.xz     | file listing              | extract, open in Finder          |

Environment variables:

| Variable                | Effect                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| `SCRY_DEBUG=1`          | Print the detected terminal width to stderr                      |
| `SCRY_USER_HANDLERS`    | Directory to load your own handlers from (see below)             |
| `SCRY_SHARE`            | Where to find `lib.sh` and the built-in handlers (rarely needed) |

## Adding your own file types

Each file type is a small handler script. The built-in ones live in
[`share/scry/handlers/`](share/scry/handlers); yours go in
`~/.config/scry/handlers/` (or `$XDG_CONFIG_HOME/scry/handlers/`, or
wherever `SCRY_USER_HANDLERS` points). Any `*.sh` file there is loaded after
the built-ins, so a handler that claims an extension already taken wins.

A handler declares itself, optionally lists the helper program it needs, and
defines one function, `scry_view_<name>`, which receives the file path:

```bash
# ~/.config/scry/handlers/json.sh
scry_register json "json jsonl" "jq, pretty-printed"
scry_helper jq "json" "brew install jq"

scry_view_json() {
    scry_require jq "brew install jq"
    jq -C . "$1" | less -R
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
| `scry_show_image FILE`                  | Show an image the way scry does                                |
| `scry_bat_view ARGS...`                 | Run `bat` at the right terminal width                          |
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

- **The Homebrew helpers.** `bat`, `glow` and the rest may be used by other
  tools. `make uninstall-deps` lists the ones that are installed and asks
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
