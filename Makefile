.PHONY:all clean mrproper test-ast
PARSER_GEN=greg
DATE=$(shell date +%Y-%m-%d)
TIME=$(shell date +%H:%M)
OOC_OWN_FLAGS=-sourcepath=source/ -driver=sequence -noclean -g -shout -v +-w +-DROCK_BUILD_DATE=\\\"${DATE}\\\" +-DROCK_BUILD_TIME=\\\"${TIME}\\\"
OOC=ooc ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	mkdir -p source/rock/parser/
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c
	${OOC} $(shell find source/ -name "*.c") rock/rock -o=bin/rock

test-ast:
	${OOC} rock/test-ast

test:
	make all && bin/rock < samples/ooc/hi-world.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf bin/rock
