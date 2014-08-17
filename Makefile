.PHONY: all clean mrproper prepare_bootstrap bootstrap install download-bootstrap rescue backup extensions extensions-clean
.SILENT: extensions extensions-clean

VENDOR_PREFIX:=$(PWD)/vendor-prefix
PARSER_GEN:=greg
NQ_PATH:=source/rock/frontend/NagaQueen.c
OOC_WARN_FLAGS?=+-w
OOC_OWN_FLAGS:=-v -pg -O3 $(OOC_WARN_FLAGS) -I$(VENDOR_PREFIX)/include -L$(VENDOR_PREFIX)/lib --gc=dynamic

# used to be CC?=gcc, but that breaks on mingw where CC is set to 'cc' apparently
CC=gcc
PREFIX?=/usr
MAN_INSTALL_PATH?=/usr/local/man/man1
BIN_INSTALL_PATH?=$(PREFIX)/bin

OOC?=rock
OOC_CMD:=$(OOC) $(OOC_OWN_FLAGS) $(OOC_FLAGS)

IS_BOOTSTRAP:=$(wildcard build/Makefile)

all: bootstrap

# Regenerate NagaQueen.c from the greg grammar
# you need ../nagaqueen and greg to be in your path
#
# http://github.com/nddrylliog/nagaqueen
# http://github.com/nddrylliog/greg
grammar:
	$(PARSER_GEN) ../nagaqueen/grammar/nagaqueen.leg > $(NQ_PATH)

# Prepares the build/ directory, used for bootstrapping
# The build/ directory contains all the C sources needed to build rock
# and a nice Makefile, too
prepare_bootstrap:
	@echo "Preparing boostrap (in build/ directory)"
	rm -rf build/
	$(OOC) -driver=make rock.use --outpath=c-source -o=../bin/c_rock -v -pg +-w
	@echo "Done!"

boehmgc:
	$(MAKE) boehmgc-clean
	mkdir -p $(VENDOR_PREFIX)
	mkdir -p vendor-build
	(cd vendor-build && ../vendor/gc/configure --prefix=$(VENDOR_PREFIX) --disable-shared --enable-static && $(MAKE) && $(MAKE) install)
	rm -rf vendor-build

boehmgc-clean:
	rm -rf vendor-prefix vendor-build

# For c-source based rock releases, 'make bootstrap' will compile a version
# of rock from the C sources in build/, then use that version to re-compile itself
bootstrap: boehmgc 
ifneq ($(IS_BOOTSTRAP),)
	@echo "Creating bin/ in case it does not exist."
	mkdir -p bin/
	@echo "Compiling from C source"
	cd build/ && ROCK_DIST=.. CFLAGS="-I$(VENDOR_PREFIX)/include" LDFLAGS="-L$(VENDOR_PREFIX)/lib" GC_PATH="-lgc" PREFIX=$(VENDOR_PREFIX) $(MAKE) -j4
	@echo "Now re-compiling ourself"
	OOC=bin/c_rock ROCK_DIST=. $(MAKE) self
	@echo "Congrats! you have a boostrapped version of rock in bin/rock now. Have fun!"
else
	@cat BOOTSTRAP
	@exit 1
endif

half-bootstrap: boehmgc
	@echo "Creating bin/ in case it does not exist."
	mkdir -p bin/
	@echo "Compiling from C source"
	cd build/ && ROCK_DIST=.. $(MAKE) -j4
	@echo "Renaming c_rock to rock"
	mv bin/c_rock bin/rock
	@echo "Congrats! you have a half-boostrapped version of rock in bin/rock now. Have fun!"

# Copy the manpage and create a symlink to the binary
install:
	if [ -e $(BIN_INSTALL_PATH)/rock ]; then echo "$(BIN_INSTALL_PATH)/rock already exists, overwriting."; rm -f $(BIN_INSTALL_PATH)/rock $(BIN_INSTALL_PATH)/rock.exe; fi
	ln -s $(PWD)/bin/rock* $(BIN_INSTALL_PATH)/
	install -d $(MAN_INSTALL_PATH)
	install docs/rock.1 $(MAN_INSTALL_PATH)/

# Regenerate the man page from docs/rock.1.txt You need ascidoc for that
man:
	cd docs/ && a2x -f manpage rock.1.txt

# Compile rock with itself
self:
	mkdir -p bin/
	$(OOC_CMD) rock.use -o=bin/rock

# Save your rock binary under bin/safe_rock
backup:
	cp bin/rock bin/safe_rock

download-bootstrap:
	rm -rf build/
	# Note: ./utils/downloader tries curl, ftp, and then wget.
	#        GNU ftp will _not_ work: it does not accept a url as an argument.
	./utils/downloader.sh http://downloads.ooc-lang.org/rock/0.9.9/latest-bootstrap.tar.bz2 | tar xjmf - 1>/dev/null
	if [ ! -e build ]; then cp -rfv rock-*/build ./; fi

# Attempt to grab a rock bootstrap from Alpaca and recompile
rescue: download-bootstrap
	$(MAKE) clean bootstrap

quick-rescue: download-bootstrap
	$(MAKE) clean half-bootstrap

# Compile rock with the backup'd version of itself
safe:
	OOC='bin/safe_rock' $(MAKE) self

bootstrap_tarball:
ifeq ($(VERSION),)
	@echo "You must specify VERSION. Generates rock-VERSION-bootstrap-only.tar.bz2"
else
	$(MAKE) prepare_bootstrap
	tar cjvfm rock-$(VERSION)-bootstrap-only.tar.bz2 build
endif

# Clean all temporary files that may make a build fail
clean:
	rm -rf *_tmp/ .libs/
	rm -rf `find build/ -name '*.o'`

# === Extensions ===

extensions:
	cd extensions && $(MAKE)

extensions-clean:
	cd extensions && $(MAKE) clean
