.PHONY:all clean mrproper test-ast
OOC_OWN_FLAGS=-sourcepath=source/ -driver=sequence -v -noclean -g
OOC=ooc ${OOC_OWN_FLAGS} ${OOC_FLAGS}

all:
	${OOC} rock/rock && mv rock bin/

test-ast:
	${OOC} rock/test-ast

test:
	make all && ./rock source/rock.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf ./rock
