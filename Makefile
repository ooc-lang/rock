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

OOC?=ooc
OOC_CMD=${OOC} ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	mkdir -p source/rock/parser/
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c
	${OOC_CMD} $(shell find source/ -name "*.c") rock/rock -o=bin/rock

test-ast:
	${OOC_CMD} rock/test-ast

test:
	make all && bin/rock < samples/ooc/hi-world.ooc

slave:
	OOC_FLAGS="${OOC_FLAGS} -slave" make

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf bin/rock
