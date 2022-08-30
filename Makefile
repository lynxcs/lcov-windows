#
# Makefile for LCOV
#
# Make targets:
#   - install:   install LCOV tools and man pages on the system
#   - uninstall: remove tools and man pages from the system
#   - dist:      create files required for distribution, i.e. the lcov.tar.gz
#                and the lcov.rpm file. Just make sure to adjust the VERSION
#                and RELEASE variables below - both version and date strings
#                will be updated in all necessary files.
#   - clean:     remove all generated files
#   - release:   finalize release and create git tag for specified VERSION
#

ifeq ($(MAKE),mingw32-make)
	DESTDIR := "C:/Program Files/LCOV"
	TMP_DIR := $(TEMP)
    PERL    := perl
else
	PREFIX := /usr/local
	TMP_DIR := $(shell mktemp -d)
    PERL    := env perl
endif

VERSION := $(shell $(PERL) bin/get_version.pl --version)
RELEASE := $(shell $(PERL) bin/get_version.pl --release)
FULL    := $(shell $(PERL) bin/get_version.pl --full)

# Set this variable during 'make install' to specify the Perl interpreter used in
# installed scripts, or leave empty to keep the current interpreter.
export LCOV_PERL_PATH := /usr/bin/perl

CFG_DIR := $(PREFIX)/etc
BIN_DIR := $(PREFIX)/bin
MAN_DIR := $(PREFIX)/share/man
FILES   := $(wildcard bin/*) $(wildcard man/*) README Makefile \
	   $(wildcard rpm/*) lcovrc

.PHONY: all info clean install uninstall rpms test

all: info

info:
	@echo "Available make targets:"
	@echo "  install   : install binaries and man pages in DESTDIR (default /)"
	@echo "  uninstall : delete binaries and man pages from DESTDIR (default /)"
	@echo "  dist      : create packages (RPM, tarball) ready for distribution"
	@echo "  check     : perform self-tests"
	@echo "  release   : finalize release and create git tag for specified VERSION"

clean:
	rm -f lcov-*.tar.gz
	rm -f lcov-*.rpm
	make -C example clean
	make -C tests -s clean

install:
	$(PERL) bin/install.pl bin/lcov $(DESTDIR)$(BIN_DIR)/lcov -m 755
	$(PERL) bin/install.pl bin/genhtml $(DESTDIR)$(BIN_DIR)/genhtml -m 755
	$(PERL) bin/install.pl bin/geninfo $(DESTDIR)$(BIN_DIR)/geninfo -m 755
	$(PERL) bin/install.pl bin/genpng $(DESTDIR)$(BIN_DIR)/genpng -m 755
	$(PERL) bin/install.pl bin/gendesc $(DESTDIR)$(BIN_DIR)/gendesc -m 755
	$(PERL) bin/install.pl man/lcov.1 $(DESTDIR)$(MAN_DIR)/man1/lcov.1 -m 644
	$(PERL) bin/install.pl man/genhtml.1 $(DESTDIR)$(MAN_DIR)/man1/genhtml.1 -m 644
	$(PERL) bin/install.pl man/geninfo.1 $(DESTDIR)$(MAN_DIR)/man1/geninfo.1 -m 644
	$(PERL) bin/install.pl man/genpng.1 $(DESTDIR)$(MAN_DIR)/man1/genpng.1 -m 644
	$(PERL) bin/install.pl man/gendesc.1 $(DESTDIR)$(MAN_DIR)/man1/gendesc.1 -m 644
	$(PERL) bin/install.pl man/lcovrc.5 $(DESTDIR)$(MAN_DIR)/man5/lcovrc.5 -m 644
	$(PERL) bin/install.pl lcovrc $(DESTDIR)$(CFG_DIR)/lcovrc -m 644
	$(PERL) bin/updateversion.pl $(DESTDIR)$(BIN_DIR)/lcov $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(BIN_DIR)/genhtml $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(BIN_DIR)/geninfo $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(BIN_DIR)/genpng $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(BIN_DIR)/gendesc $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man1/lcov.1 $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man1/genhtml.1 $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man1/geninfo.1 $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man1/genpng.1 $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man1/gendesc.1 $(VERSION) $(RELEASE) $(FULL)
	$(PERL) bin/updateversion.pl $(DESTDIR)$(MAN_DIR)/man5/lcovrc.5 $(VERSION) $(RELEASE) $(FULL)

uninstall:
	$(PERL) bin/install.pl --uninstall bin/lcov $(DESTDIR)$(BIN_DIR)/lcov
	$(PERL) bin/install.pl --uninstall bin/genhtml $(DESTDIR)$(BIN_DIR)/genhtml
	$(PERL) bin/install.pl --uninstall bin/geninfo $(DESTDIR)$(BIN_DIR)/geninfo
	$(PERL) bin/install.pl --uninstall bin/genpng $(DESTDIR)$(BIN_DIR)/genpng
	$(PERL) bin/install.pl --uninstall bin/gendesc $(DESTDIR)$(BIN_DIR)/gendesc
	$(PERL) bin/install.pl --uninstall man/lcov.1 $(DESTDIR)$(MAN_DIR)/man1/lcov.1
	$(PERL) bin/install.pl --uninstall man/genhtml.1 $(DESTDIR)$(MAN_DIR)/man1/genhtml.1
	$(PERL) bin/install.pl --uninstall man/geninfo.1 $(DESTDIR)$(MAN_DIR)/man1/geninfo.1
	$(PERL) bin/install.pl --uninstall man/genpng.1 $(DESTDIR)$(MAN_DIR)/man1/genpng.1
	$(PERL) bin/install.pl --uninstall man/gendesc.1 $(DESTDIR)$(MAN_DIR)/man1/gendesc.1
	$(PERL) bin/install.pl --uninstall man/lcovrc.5 $(DESTDIR)$(MAN_DIR)/man5/lcovrc.5
	$(PERL) bin/install.pl --uninstall lcovrc $(DESTDIR)$(CFG_DIR)/lcovrc

ifneq ($(MAKE),mingw32-make)

clean:
	$(RM) lcov-*.tar.gz
	$(RM) lcov-*.rpm
	$(MAKE) -C example clean
	$(MAKE) -C test -s clean

dist: lcov-$(VERSION).tar.gz lcov-$(VERSION)-$(RELEASE).noarch.rpm \
      lcov-$(VERSION)-$(RELEASE).src.rpm

lcov-$(VERSION).tar.gz: $(FILES)
	mkdir $(TMP_DIR)/lcov-$(VERSION)
	cp -r * $(TMP_DIR)/lcov-$(VERSION)
	bin/copy_dates.sh . $(TMP_DIR)/lcov-$(VERSION)
	make -C $(TMP_DIR)/lcov-$(VERSION) clean
	bin/updateversion.pl $(TMP_DIR)/lcov-$(VERSION) $(VERSION) $(RELEASE) $(FULL)
	bin/get_changes.sh > $(TMP_DIR)/lcov-$(VERSION)/CHANGES
	cd $(TMP_DIR) ; \
	tar cfz $(TMP_DIR)/lcov-$(VERSION).tar.gz lcov-$(VERSION) \
	    --owner root --group root
	mv $(TMP_DIR)/lcov-$(VERSION).tar.gz .
	rm -rf $(TMP_DIR)

lcov-$(VERSION)-$(RELEASE).noarch.rpm: rpms
lcov-$(VERSION)-$(RELEASE).src.rpm: rpms

rpms: lcov-$(VERSION).tar.gz
	mkdir $(TMP_DIR)
	mkdir $(TMP_DIR)/BUILD
	mkdir $(TMP_DIR)/RPMS
	mkdir $(TMP_DIR)/SOURCES
	mkdir $(TMP_DIR)/SRPMS
	cp lcov-$(VERSION).tar.gz $(TMP_DIR)/SOURCES
	cd $(TMP_DIR)/BUILD ; \
	tar xfz $(TMP_DIR)/SOURCES/lcov-$(VERSION).tar.gz \
		lcov-$(VERSION)/rpm/lcov.spec
	rpmbuild --define '_topdir $(TMP_DIR)' --define '_buildhost localhost' \
		 --undefine vendor --undefine packager \
		 -ba $(TMP_DIR)/BUILD/lcov-$(VERSION)/rpm/lcov.spec
	mv $(TMP_DIR)/RPMS/noarch/lcov-$(VERSION)-$(RELEASE).noarch.rpm .
	mv $(TMP_DIR)/SRPMS/lcov-$(VERSION)-$(RELEASE).src.rpm .
	rm -rf $(TMP_DIR)

test: check

check:
	@make -s -C tests check

release:
	@if [ "$(origin VERSION)" != "command line" ] ; then echo "Please specify new version number, e.g. VERSION=1.16" >&2 ; exit 1 ; fi
	@if [ -n "$$(git status --porcelain 2>&1)" ] ; then echo "The repository contains uncommited changes" >&2 ; exit 1 ; fi
	@if [ -n "$$(git tag -l v$(VERSION))" ] ; then echo "A tag for the specified version already exists (v$(VERSION))" >&2 ; exit 1 ; fi
	@echo "Preparing release tag for version $(VERSION)"
	git checkout master
	bin/copy_dates.sh . .
	for FILE in README man/* rpm/* ; do \
		bin/updateversion.pl "$$FILE" $(VERSION) 1 $(VERSION) ; \
	done
	git commit -a -s -m "lcov: Finalize release $(VERSION)"
	git tag v$(VERSION) -m "LCOV version $(VERSION)"
	@echo "**********************************************"
	@echo "Release tag v$(VERSION) successfully created"
	@echo "Next steps:"
	@echo " - Review resulting commit and tag"
	@echo " - Publish with: git push origin master v$(VERSION)"
	@echo "**********************************************"