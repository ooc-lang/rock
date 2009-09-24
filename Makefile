.PHONY:all clean mrproper

all:
	ooc rock -sourcepath=source/ +-Os ${OOC_FLAGS}

test:
	make all && ./rock source/rock.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf ./rock
