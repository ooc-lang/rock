
.PHONY: all clean

# try to determine the OS and architecture
MYOS := $(shell uname -s)
MACHINE := $(shell uname -m)
ifeq ($(MYOS), Linux)
    ARCH=linux
else ifeq ($(MYOS), FreeBSD)
    ARCH=freebsd
else ifeq ($(MYOS), OpenBSD)
    ARCH=openbsd
else ifeq ($(MYOS), NetBSD)
    ARCH=netbsd
else ifeq ($(MYOS), DragonFly)
    ARCH=dragonfly
else ifeq ($(MYOS), Darwin)
    ARCH=osx
else ifeq ($(MYOS), CYGWIN_NT-5.1)
    ARCH=win
else ifeq ($(MYOS), MINGW32_NT-5.1)
    ARCH=win
else ifeq ($(MYOS), MINGW32_NT-6.1)
	ARCH=win
else ifeq ($(MYOS), MSYS_NT-6.1)
    ARCH=win
else ifeq ($(MYOS),)
  ifeq (${OS}, Windows_NT)
    ARCH=win
  else
    $(error "OS ${OS} unrecognized - please open an issue at https://github.com/fasterthanlime/rock/issues")
  endif
endif

ifeq ($(ARCH), win)
MAKE_FILE=Makefile.win32
else ifeq ($(ARCH), linux)
MAKE_FILE=Makefile.linux
else ifeq ($(ARCH), osx)
MAKE_FILE=Makefile.osx
else
MAKE_FILE=Makefile.platform-unsupported
endif

build:
	BINDIR=../../bin $(MAKE) -f ${MAKE_FILE} build
	@echo "fancy-backtrace compiled!"

clean:
	$(MAKE) -f ${MAKE_FILE} clean
	@echo "fancy-backtrace cleaned!"

