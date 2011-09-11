
# try to determine the OS and architecture
MYOS := $(shell uname -s)
MACHINE := $(shell uname -m)
ifeq ($(MYOS), Linux)
    ARCH=linux
else ifeq ($(MYOS), FreeBSD)
    ARCH=freebsd
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
GC_PREFIX?=/usr/lib/

LIBGC_PRESENT?=$(wildcard ${GC_PREFIX}/libgc.a)
LIBGC_SUPPORTS_THREADS?=$(shell nm $(wildcard ${GC_PREFIX}/libgc.a) | grep GC_pthread_create)

all:
	mkdir -p ${GC_PATH}
ifdef LIBGC_PRESENT
ifdef LIBGC_SUPPORTS_THREADS
	@echo "Using system libgc"
	cp /usr/lib/libgc.a ${GC_PATH}
else
	@echo "System libgc doesn't support threads, building our own"
	make buildgc
endif
else
	@echo "No system libgc, building our own"
	make buildgc
endif

buildgc:
	cd sources && ./configure --enable-threads=posix --enable-thread-local-alloc && make
	cp sources/.libs/libgc.a ${GC_PATH}
