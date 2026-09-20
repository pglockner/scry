PREFIX ?= $(HOME)/.local
BINDIR   = $(DESTDIR)$(PREFIX)/bin
SHAREDIR = $(DESTDIR)$(PREFIX)/share/scry
QLMD_APPEX = /Applications/QLMarkdown.app/Contents/PlugIns/Markdown QL Extension.appex
DEP_FORMULAE = bat glow viu visidata f3d

.PHONY: help install link uninstall deps deps-data deps-3d deps-quicklook \
	uninstall-quicklook uninstall-deps lint doctor

help:
	@echo "make install              copy scry to $(PREFIX) (override with PREFIX=...)"
	@echo "make link                 symlink to this checkout instead, for development"
	@echo "make uninstall            remove what install/link put in $(PREFIX)"
	@echo "make deps                 install core helpers (bat, glow, viu)"
	@echo "make deps-data            + visidata, for csv/tsv"
	@echo "make deps-3d              + f3d, for stl/3mf (large)"
	@echo "make deps-quicklook       + qlmarkdown, for scry -f on markdown"
	@echo "make uninstall-quicklook  undo deps-quicklook"
	@echo "make uninstall-deps       optionally brew-uninstall the helpers (asks first)"
	@echo "make lint                 shellcheck the scripts"
	@echo "make doctor               show which helpers are installed"

install:
	install -d "$(BINDIR)" "$(SHAREDIR)/handlers"
	install -m 755 bin/scry "$(BINDIR)/scry"
	install -m 644 share/scry/lib.sh "$(SHAREDIR)/lib.sh"
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
	brew bundle --file=Brewfile

deps-data:
	brew bundle --file=Brewfile.data

deps-3d:
	brew bundle --file=Brewfile.3d

deps-quicklook:
	brew bundle --file=Brewfile.quicklook
	@if ! pluginkit -m | grep -q org.sbarex.QLMarkdown.QLExtension; then \
		echo "Registering QLMarkdown Quick Look extension..."; \
		pluginkit -a "$(QLMD_APPEX)"; \
		qlmanage -r >/dev/null 2>&1; \
		qlmanage -r cache >/dev/null 2>&1; \
	fi

uninstall-quicklook:
	-pluginkit -r "$(QLMD_APPEX)"
	-brew uninstall --cask qlmarkdown
	-qlmanage -r >/dev/null 2>&1
	-qlmanage -r cache >/dev/null 2>&1

# Helpers may be used by other tools (bat and glow often are), so this
# asks first and only touches formulae that are actually installed.
uninstall-deps:
	@installed=""; for p in $(DEP_FORMULAE); do \
		brew list --formula "$$p" >/dev/null 2>&1 && installed="$$installed $$p"; \
	done; \
	if [ -z "$$installed" ]; then echo "None of the helpers are installed."; exit 0; fi; \
	echo "Installed helpers:$$installed"; \
	printf "brew uninstall these? Other tools may use them. [y/N] "; read ans; \
	if [ "$$ans" = y ] || [ "$$ans" = Y ]; then brew uninstall $$installed; else echo "Skipped."; fi

lint:
	shellcheck bin/scry share/scry/lib.sh share/scry/handlers/*.sh

doctor:
	@bin/scry --doctor
