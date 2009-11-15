.PHONY:all clean mrproper test-ast
#PARSER_GEN=leg
PARSER_GEN=greg
OOC_OWN_FLAGS=-sourcepath=source/ -driver=sequence -v -noclean -g -shout
OOC=ooc ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	mkdir -p source/rock/parser/
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c
	${OOC} $(shell find source/ -name "*.c") rock/rock && mkdir -p bin/ && mv rock bin/

test-ast:
	${OOC} rock/test-ast

test:
	make all && bin/rock < samples/ooc/hi-world.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf bin/rock
