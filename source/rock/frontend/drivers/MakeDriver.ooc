import io/[File, FileWriter]

import structs/[List, ArrayList, HashMap]
import ../[BuildParams]
import ../compilers/AbstractCompiler
import ../../middle/Module
import ../../backend/cnaughty/CGenerator
import Driver

/**
   Generate the .c source files in a build/ directory, along with a
   Makefile that allows to build a version of your program without any
   ooc-related dependency.

   :author: Amos Wenger (nddrylliog)
 */
MakeDriver: class extends Driver {

    makefile: File

    init: func (.params) { super(params) }

    setup: func {
        wasSetup := static false
        if(wasSetup) return

        // build/rock_tmp/
        params outPath mkdirs()

        // build/Makefile
        makefile = File new(params outPath, "Makefile")

        wasSetup = true
    }

    compile: func (module: Module) -> Int {

        setup()

        params outPath mkdirs()

        "Spawning bunnies in %s" printfln(makefile path)

        toCompile := module collectDeps()
        for(candidate in toCompile) {
            CGenerator new(params, candidate) write()
        }

        copyLocalHeaders(module, params, ArrayList<Module> new())

        fW := FileWriter new(makefile)

        fW write("CC=%s\n" format(params compiler executablePath))

        fW write("# try to determine the OS and architecture\n")
        fW write("MYOS := $(shell uname -s)\n")
        fW write("MACHINE := $(shell uname -m)\n")
        fW write("ifeq ($(MYOS), Linux)\n")
        fW write("    ARCH=linux\n")
        fW write("else ifeq ($(MYOS), FreeBSD)\n")
        fW write("    ARCH=freebsd\n")
        fW write("else ifeq ($(MYOS), Darwin)\n")
        fW write("    ARCH=osx\n")
        fW write("else ifeq ($(MYOS), CYGWIN_NT-5.1)\n")
        fW write("    ARCH=win\n")
        fW write("else ifeq ($(MYOS), MINGW32_NT-5.1)\n")
        fW write("    ARCH=win\n")
        fW write("else ifeq ($(MYOS), MINGW32_NT-6.1)\n")
        fW write("    ARCH=win\n")
        fW write("else ifeq ($(MYOS),)\n")
        fW write("  ifeq (${OS}, Windows_NT)\n")
        fW write("    ARCH=win\n")
        fW write("  else\n")
        fW write("    $(error \"OS ${OS} doesn't have pre-built Boehm GC packages. Please compile and install your own and recompile with GC_PATH=-lgc\")\n")
        fW write("  endif\n")
        fW write("endif\n")

        fW write("ifneq ($(ARCH), osx)\n")
        fW write("  ifeq ($(MACHINE), x86_64)\n")
        fW write("    ARCH:=${ARCH}64\n")
        fW write("  else ifeq (${PROCESSOR_ARCHITECTURE}, AMD64)\n")
        fW write("    ARCH:=${ARCH}64\n")
        fW write("  else\n")
        fW write("    ARCH:=${ARCH}32\n")
        fW write("  endif\n")
        fW write("endif\n")

        fW write("# this folder must contains libs/\n")
        fW write("ROCK_DIST?=.\n")

        fW write("ifeq ($(MYOS), FreeBSD)\n")
        fW write("    GC_PATH?=-lgc\n")
        fW write("else\n")
        fW write("    # uncomment to link dynamically with the gc instead (e.g. -lgc)\n")
        fW write("    #GC_PATH?=-lgc\n")
        fW write("    GC_PATH?=${ROCK_DIST}/libs/${ARCH}/libgc.a\n")
        fW write("endif\n")

        fW write("CFLAGS+=-I .")
        fW write(" -I ${ROCK_DIST}/libs/headers/ -L/usr/local/lib -I/usr/local/include")

        if(params debug) {
            fW write(" -g")
        }

        params compiler reset()
        iter := params compiler command iterator()
        iter next()
        while(iter hasNext?()) {
            fW write(" "). write(iter next())
        }

        for(define in params defines) {
            fW write(" -D"). write(define)
        }

        for(compilerArg in params compilerArgs) {
            fW write(" "). write(compilerArg)
        }

        for(incPath in params incPath getPaths()) {
            fW write(" -I "). write(incPath getPath())
        }

        fW write("\n")

        fW write("EXECUTABLE=")
        fW write(module simpleName)
        fW write("\n")

        fW write("OBJECT_FILES:=")

        for(currentModule in toCompile) {
            path := currentModule getPath("")
            fW write(path). write(".o ")
        }

        fW write("\n\n.PHONY: compile link clean\n\n")

        fW write("all: compile link\n\n")

        fW write("compile: ${OBJECT_FILES}")

        fW write("\n\t@echo \"Finished compiling for arch ${ARCH}\"\n")

        fW write("\n\n")

        oPaths := ArrayList<String> new()

        for(currentModule in toCompile) {
            path := currentModule getPath("")
            oPath := path + ".o"
            cPath := path + ".c"
            oPaths add(oPath)

            fW write(oPath). write(": ").
               write(cPath). write(" ").
               write(path). write(".h ").
               write(path). write("-fwd.h\n")

            fW write("\t${CC} ${CFLAGS} -c %s -o %s\n" format(cPath, oPath))
        }

        fW write("\nlink: ${OBJECT_FILES}\n")

        fW write("\t${CC} ${CFLAGS} ${OBJECT_FILES} ")

        for(dynamicLib in params dynamicLibs) {
            fW write(" -l "). write(dynamicLib)
        }

        for(additional in params additionals) {
            fW write(" "). write(additional)
        }

        for(libPath in params libPath getPaths()) {
            fW write(" -L "). write(libPath getPath())
        }

        fW write(" -o ${EXECUTABLE}")

        libs := getFlagsFromUse(module)
        for(lib in libs) {
            fW write(" "). write(lib)
        }

        fW write(" ${GC_PATH}")

        fW write("\n\n")

        fW write("\nclean:")
        fW write("\n\t rm -f ${OBJECT_FILES} ${EXECUTABLE}")

        fW close()

        return 0

    }

}
