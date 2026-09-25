PREFIX ?= $(HOME)/.local
BINDIR   = $(DESTDIR)$(PREFIX)/bin
SHAREDIR = $(DESTDIR)$(PREFIX)/share/scry
QLMD_APPEX = /Applications/QLMarkdown.app/Contents/PlugIns/Markdown QL Extension.appex
DEP_FORMULAE = bat glow viu visidata f3d fzf mpv pandoc poppler antiword ffmpeg

# The deps targets use Homebrew, which also runs on Linux. Without it, say
# what to do instead of failing on "brew: command not found".
BREW = @command -v brew >/dev/null 2>&1 || { \
	echo "Homebrew not found. Install it (https://brew.sh, Linux too), or install the"; \
	echo "helpers with your package manager: see the README, and run scry --doctor."; \
	exit 1; }; brew
# Each recipe line runs in its own shell, so stopping the rest of a target
# takes a failing line, not `exit 0`.
MACOS_ONLY = @[ "$$(uname -s)" = Darwin ] || { echo "Quick Look is macOS-only."; exit 1; }

.PHONY: help install link uninstall deps deps-data deps-3d deps-audio deps-fzf deps-linux \
	deps-quicklook uninstall-quicklook uninstall-deps lint test doctor

help:
	@echo "make install              copy scry to $(PREFIX) (override with PREFIX=...)"
	@echo "make link                 symlink to this checkout instead, for development"
	@echo "make uninstall            remove what install/link put in $(PREFIX)"
	@echo "make deps                 install core helpers (bat, glow, viu)"
	@echo "make deps-data            + visidata, for csv/tsv"
	@echo "make deps-3d              + f3d, for stl/3mf (large)"
	@echo "make deps-audio           + mpv, audio progress, -f album art, ogg/opus"
	@echo "make deps-fzf             + fzf, for scry --fzf (file picker with previews)"
	@echo "make deps-linux           + pandoc, poppler, antiword, ffmpeg (Linux only)"
	@echo "make deps-quicklook       + qlmarkdown, for scry -f on markdown (macOS only)"
	@echo "make uninstall-quicklook  undo deps-quicklook"
	@echo "make uninstall-deps       optionally brew-uninstall the helpers (asks first)"
	@echo "make lint                 shellcheck the scripts"
	@echo "make test                 run the test suite (stubs every helper)"
	@echo "make doctor               show which helpers are installed"

# Replaces the handlers and platform dirs wholesale, so a file renamed or
# removed in this version doesn't linger and load alongside its successor.
# Removes bin/scry first too: after `make link` it's a symlink to this
# checkout, and BSD install (macOS) refuses to copy a file onto itself.
install:
	rm -f "$(BINDIR)/scry"
	rm -rf "$(SHAREDIR)/handlers" "$(SHAREDIR)/platform"
	install -d "$(BINDIR)" "$(SHAREDIR)/handlers" "$(SHAREDIR)/platform"
	install -m 755 bin/scry "$(BINDIR)/scry"
	install -m 644 share/scry/lib.sh "$(SHAREDIR)/lib.sh"
	install -m 644 share/scry/platform/*.sh "$(SHAREDIR)/platform/"
	install -m 644 share/scry/handlers/*.sh "$(SHAREDIR)/handlers/"
	@echo "Installed $(BINDIR)/scry and $(SHAREDIR)"
	@case ":$$PATH:" in *":$(PREFIX)/bin:"*) ;; *) echo "Note: $(PREFIX)/bin is not on your PATH." ;; esac

link:
	install -d "$(BINDIR)"
	ln -sf "$(CURDIR)/bin/scry" "$(BINDIR)/scry"
	@echo "Linked $(BINDIR)/scry -> $(CURDIR)/bin/scry"

uninstall:
	rm -f "$(BINDIR)/scry"
	rm -rf "$(SHAREDIR)"
	@echo "Removed scry from $(PREFIX). Helpers (bat, glow, ...) and any"
	@echo "handlers in ~/.config/scry/handlers were left alone; see the README."

deps:
	$(BREW) bundle --file=Brewfile

deps-data:
	$(BREW) bundle --file=Brewfile.data

deps-3d:
	$(BREW) bundle --file=Brewfile.3d

deps-audio:
	$(BREW) bundle --file=Brewfile.audio

deps-fzf:
	$(BREW) bundle --file=Brewfile.fzf

deps-linux:
	$(BREW) bundle --file=Brewfile.linux

deps-quicklook:
	$(MACOS_ONLY)
	$(BREW) bundle --file=Brewfile.quicklook
	@if ! pluginkit -m | grep -q org.sbarex.QLMarkdown.QLExtension; then \
		echo "Registering QLMarkdown Quick Look extension..."; \
		pluginkit -a "$(QLMD_APPEX)"; \
		qlmanage -r >/dev/null 2>&1; \
		qlmanage -r cache >/dev/null 2>&1; \
	fi

uninstall-quicklook:
	$(MACOS_ONLY)
	-pluginkit -r "$(QLMD_APPEX)"
	-brew uninstall --cask qlmarkdown
	-qlmanage -r >/dev/null 2>&1
	-qlmanage -r cache >/dev/null 2>&1

# Helpers may be used by other tools (bat and glow often are), so this
# asks first and only touches formulae that are actually installed.
uninstall-deps:
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew not found; remove helpers with your package manager."; exit 0; }; \
	installed=""; for p in $(DEP_FORMULAE); do \
		brew list --formula "$$p" >/dev/null 2>&1 && installed="$$installed $$p"; \
	done; \
	if [ -z "$$installed" ]; then echo "None of the helpers are installed."; exit 0; fi; \
	echo "Installed helpers:$$installed"; \
	printf "brew uninstall these? Other tools may use them. [y/N] "; read ans; \
	if [ "$$ans" = y ] || [ "$$ans" = Y ]; then brew uninstall $$installed; else echo "Skipped."; fi

lint:
	shellcheck bin/scry share/scry/lib.sh share/scry/platform/*.sh share/scry/handlers/*.sh test/run.sh

test:
	test/run.sh

doctor:
	@bin/scry --doctor
