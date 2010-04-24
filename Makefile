.PHONY: all clean mrproper prepare_bootstrap bootstrap install
PARSER_GEN=greg
NQ_PATH=source/rock/frontend/NagaQueen.c
DATE=$(shell date +%Y-%m-%d)
TIME=$(shell date +%H:%M)
OOC_OWN_FLAGS=-sourcepath=source -driver=sequence -noclean -g -v -shout +-w

PREFIX?=/usr
MAN_INSTALL_PATH?=/usr/local/man/man1
BIN_INSTALL_PATH?=${PREFIX}/bin

ifdef WINDIR
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\\\"${DATE}\\\" +-DROCK_BUILD_TIME=\\\"${TIME}\\\"
else
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\"${DATE}\" +-DROCK_BUILD_TIME=\"${TIME}\"
endif

OOC?=rock
OOC_CMD=${OOC} ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all: bootstrap

# Regenerate NagaQueen.c from the greg grammar
# you need ../nagaqueen and greg to be in your path
#
# http://github.com/nddrylliog/nagaqueen
# http://github.com/nddrylliog/greg
grammar:
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c

# Prepares the build/ directory, used for bootstrapping
# The build/ directory contains all the C sources needed to build rock
# and a nice Makefile, too
prepare_bootstrap:
	@echo "Preparing boostrap (in build/ directory)"
	rm -rf build/
	${OOC} -driver=make -sourcepath=source -outpath=c-source rock/rock -o=../bin/c_rock c-source/${NQ_PATH} -v -g +-w
	sed s/-w.*/-w\ -DROCK_BUILD_DATE=\\\"\\\\\"bootstrapped\\\\\"\\\"\ -DROCK_BUILD_TIME=\\\"\\\\\"\\\\\"\\\"/ -i build/Makefile
	cp ${NQ_PATH} build/c-source/${NQ_PATH}
	@echo "Done!"

# For c-source based rock releases, 'make bootstrap' will compile a version
# of rock from the C sources in build/, then use that version to re-compile itself
bootstrap:
	@echo "Compiling from C source"
	cd build/ && ROCK_DIST=.. make
	@echo "Now re-compiling ourself"
	OOC=bin/c_rock ROCK_DIST=. make self
	@echo "Congrats! you have a boostrapped version of rock in bin/rock now. Have fun!"
	
# Copy the manpage and create a symlink to the binary
install:
	chmod +x bin/*
	ln -s $(shell pwd)/bin/rock* ${BIN_INSTALL_PATH}/
	cp -f docs/rock.1 ${MAN_INSTALL_PATH}/
	
# Regenerate the man page from docs/rock.1.txt You need ascidoc for that
man:
	cd docs/ && a2x -f manpage rock.1.txt

# Compile a clean rock with itself
self:
	make clean noclean

# For rock developers - recompile without cleaning, for small changes
# that don't trigger the fragile base class problem.
#  - http://en.wikipedia.org/wiki/Fragile_base_class
# This should be fixed by caching the class hierarchy with the json backend
noclean:
	${OOC_CMD} rock/rock -o=bin/rock ${NQ_PATH}

clean:
	rm -rf *_tmp/
