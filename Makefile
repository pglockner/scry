PREFIX ?= $(HOME)/.local
BINDIR   = $(DESTDIR)$(PREFIX)/bin
SHAREDIR = $(DESTDIR)$(PREFIX)/share/scry
QLMD_APPEX = /Applications/QLMarkdown.app/Contents/PlugIns/Markdown QL Extension.appex

# Each recipe line runs in its own shell, so stopping the rest of a target
# takes a failing line, not `exit 0`.
MACOS_ONLY = @[ "$$(uname -s)" = Darwin ] || { echo "Quick Look is macOS-only."; exit 1; }

.PHONY: help install link uninstall uninstall-quicklook uninstall-deps lint test doctor

# Helpers are installed by ./install.sh, which picks the package manager.
help:
	@echo "./install.sh              install scry and its helpers (asks which; --help for more)"
	@echo "make install              copy scry to $(PREFIX) only (override with PREFIX=...)"
	@echo "make link                 symlink to this checkout instead, for development"
	@echo "make uninstall            remove what install/link put in $(PREFIX)"
	@echo "make uninstall-quicklook  undo ./install.sh --with quicklook (macOS)"
	@echo "make uninstall-deps       optionally brew-uninstall the helpers (asks first)"
	@echo "make lint                 shellcheck the scripts"
	@echo "make test                 run the test suite (stubs every helper)"
	@echo "make doctor               show which helpers are installed"

install:
	@PREFIX="$(PREFIX)" DESTDIR="$(DESTDIR)" ./install.sh --no-helpers

link:
	install -d "$(BINDIR)"
	ln -sf "$(CURDIR)/bin/scry" "$(BINDIR)/scry"
	@echo "Linked $(BINDIR)/scry -> $(CURDIR)/bin/scry"

uninstall:
	rm -f "$(BINDIR)/scry"
	rm -rf "$(SHAREDIR)"
	@echo "Removed scry from $(PREFIX). Helpers (bat, glow, ...) and any"
	@echo "handlers in ~/.config/scry/handlers were left alone; see the README."

uninstall-quicklook:
	$(MACOS_ONLY)
	-pluginkit -r "$(QLMD_APPEX)"
	-brew uninstall --cask qlmarkdown
	-qlmanage -r >/dev/null 2>&1
	-qlmanage -r cache >/dev/null 2>&1

# Helpers may be used by other tools (bat and glow often are), so this
# asks first and only touches formulae that are actually installed. The
# list is every `brew "..."` line in the Brewfiles; casks (qlmarkdown)
# have their own uninstall target.
uninstall-deps:
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew not found; remove helpers with your package manager."; exit 0; }; \
	installed=""; for p in $$(sed -n 's/^brew "\([^"]*\)".*/\1/p' Brewfile*); do \
		brew list --formula "$$p" >/dev/null 2>&1 && installed="$$installed $$p"; \
	done; \
	if [ -z "$$installed" ]; then echo "None of the helpers are installed."; exit 0; fi; \
	echo "Installed helpers:$$installed"; \
	printf "brew uninstall these? Other tools may use them. [y/N] "; read ans; \
	if [ "$$ans" = y ] || [ "$$ans" = Y ]; then brew uninstall $$installed; else echo "Skipped."; fi

lint:
	shellcheck install.sh bin/scry share/scry/lib.sh share/scry/platform/*.sh share/scry/handlers/*.sh test/run.sh

test:
	test/run.sh

doctor:
	@bin/scry --doctor
