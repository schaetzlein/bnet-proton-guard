SHELLCHECK ?= shellcheck
BATS       ?= bats
PREFIX     ?= $(HOME)/.local
BINDIR     ?= $(PREFIX)/bin

.PHONY: all lint test install

all: lint test

lint:
	$(SHELLCHECK) bnet-proton-guard tests/*.bash

test:
	$(BATS) tests/

install:
	install -Dm755 bnet-proton-guard $(DESTDIR)$(BINDIR)/bnet-proton-guard
