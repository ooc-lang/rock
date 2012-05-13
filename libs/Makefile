
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
else ifeq ($(MYOS),)
  ifeq (${OS}, Windows_NT)
    ARCH=win
  else
    $(error "OS ${OS} unrecognized - please open an issue at https://github.com/nddrylliog/rock/issues")
  endif
endif

ifeq ($(ARCH), win)
    GC_FLAGS=--enable-threads=win32 --enable-local-thread-alloc
else
    GC_FLAGS=--enable-threads=posix --enable-local-thread-alloc
endif

ifneq ($(ARCH), osx)
  ifeq ($(MACHINE), x86_64)
    ARCH:=${ARCH}64
  else ifeq (${PROCESSOR_ARCHITECTURE}, AMD64)
    ARCH:=${ARCH}64
  else
    ARCH:=${ARCH}32
  endif
endif
# this folder must contains libs/
ROCK_LIBS_DIR?=.

# uncomment to link dynamically with the gc instead (e.g. -lgc)
GC_PATH?=${ROCK_LIBS_DIR}/${ARCH}/
#GC_PREFIX?=/usr/lib/
GC_PREFIX?=$(shell pkg-config --variable=libdir bdw-gc)

LIBGC_PRESENT=$(wildcard ${GC_PREFIX}/libgc.a)
LIBGC_SUPPORTS_THREADS=$(shell nm $(wildcard ${GC_PREFIX}/libgc.a) | grep GC_pthread_create)

all:
	mkdir -p ${GC_PATH}
ifneq (${LIBGC_PRESENT},)
ifneq (${LIBGC_SUPPORTS_THREADS},)
	@echo "Using system libgc"
	cp ${GC_PREFIX}/libgc.a ${GC_PATH}
else
	@echo "System libgc doesn't support threads, building our own"
	$(MAKE) buildgc
endif
else
	@echo "No system libgc, building our own"
	$(MAKE) buildgc
endif

buildgc:
	cd sources && ./configure ${GC_FLAGS} && $(MAKE)
	cp sources/.libs/libgc.a ${GC_PATH}
