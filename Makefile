.PHONY:all clean mrproper

all:
	ooc rock -sourcepath=source/ -g ${OOC_FLAGS}

test:
	make all && ./rock source/rock.ooc

clean:
	rm -rf ooc_tmp/

mrproper: clean
	rm -rf ./rock
