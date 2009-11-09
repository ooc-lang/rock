.PHONY:all clean mrproper test-ast
OOC_OWN_FLAGS=-sourcepath=source/ -driver=sequence -v -noclean -g -shout
OOC=ooc ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	mkdir -p source/rock/parser/
	leg ../nagaqueen/grammar/nagaqueen.leg > source/rock/frontend/NagaQueen.c
	${OOC} $(shell find source/ -name "*.c") rock/rock && mkdir -p bin/ && mv rock bin/

test-ast:
	${OOC} rock/test-ast

test:
	make all && bin/rock < samples/ooc/hi-world.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf bin/rock
