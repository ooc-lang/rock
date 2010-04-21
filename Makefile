.PHONY:all clean mrproper test-ast
PARSER_GEN=greg
NQ_PATH=source/rock/frontend/NagaQueen.c
DATE=$(shell date +%Y-%m-%d)
TIME=$(shell date +%H:%M)
OOC_OWN_FLAGS=-sourcepath=source -driver=sequence -noclean -g -v -shout +-w 

ifdef WINDIR
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\\\"${DATE}\\\" +-DROCK_BUILD_TIME=\\\"${TIME}\\\"
else
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\"${DATE}\" +-DROCK_BUILD_TIME=\"${TIME}\"
endif

OOC?=rock
OOC_CMD=${OOC} ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	make clean noclean

noclean:
	${OOC_CMD} rock/rock -o=bin/rock ${NQ_PATH}

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
	${OOC} -driver=make -sourcepath=source/ -outpath=c-source/ rock/rock -o=../bin/c_rock c-source/${NQ_PATH} -v -g +-w
	sed s/-w.*/-w\ -DROCK_BUILD_DATE=\\\"\\\\\"bootstrapped\\\\\"\\\"\ -DROCK_BUILD_TIME=\\\"\\\\\"\\\\\"\\\"/ -i build/Makefile
	cp ${NQ_PATH} build/c-source/${NQ_PATH}
	@echo "Done!"

# For c-source based rock releases, 'make bootstrap' will compile a version
# of rock from the C sources in build/, then use that version to re-compile itself
bootstrap:
	@echo "Compiling from C source"
	cd build/ && ROCK_DIST=.. make
	@echo "Now re-compiling ourself"
	OOC=bin/c_rock ROCK_DIST=. make all
	@echo "Congrats! you have a boostrapped version of rock in bin/rock now. Have fun!"

clean:
	rm -rf *_tmp/
