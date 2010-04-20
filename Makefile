.PHONY:all clean mrproper test-ast
PARSER_GEN=greg
DATE=$(shell date +%Y-%m-%d)
TIME=$(shell date +%H:%M)
OOC_OWN_FLAGS=-sourcepath=source/ -driver=sequence -noclean -g -v -shout +-w 

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
	${OOC_CMD} $(shell find source/ -name "*.c") rock/rock -o=bin/rock

# Regenerate NagaQueen.c from the greg grammar
# you need ../nagaqueen and greg to be in your path
#
# http://github.com/nddrylliog/nagaqueen
# http://github.com/nddrylliog/greg
grammar:
	mkdir -p source/rock/parser/
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c

# For c-source based rock releases, 'make bootstrap' will compile a version
# of rock from the C sources in build/, then use that version to re-compile itself
bootstrap:
	@echo "Compiling from C source"
	cd build/ && make
	mv build/rock bin/rock
	@echo "Now re-compiling ourself"
	make all

clean:
	rm -rf *_tmp/