// sdk stuff
import io/[File, FileWriter]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, SequenceDriver, CCompiler, Flags, SourceFolder

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, UseDef]
import rock/backend/cnaughty/CGenerator
import rock/io/TabbedWriter

/**
 * Generate the .c source files in a build/ directory, along with a
 * CMakefile that allows to build a version of your program without any
 * ooc-related dependency.
 */
CMakeDriver: class extends SequenceDriver {

    // the self-containing directory containing buildable C sources
    builddir: File

    // build/CMakeLists.txt
    makefile: File

    // Original output path (e.g. "rock_tmp")
    originalOutPath: File

    init: func (.params) { super(params) }

    setup: func {
        wasSetup := static false
        if(wasSetup) return

        // no lib-caching for the cmake driver!
        params libcache = false

        // keeping them for later (ie. CMakefile invocation)
        params clean = false

        // build/
        builddir = File new("build")

        // build/rock_tmp/
        originalOutPath = params outPath
        params outPath = File new(builddir, params outPath getPath())
        params outPath mkdirs()

        // build/CMakeLists.txt
        makefile = File new(builddir, "CMakeLists.txt")

        wasSetup = true
    }

    compile: func (module: Module) -> Int {

        if(params verbose) {
           "CMake driver" println()
        }

        setup()

        params outPath mkdirs()

        toCompile := ArrayList<Module> new()
        sourceFolders := collectDeps(module, HashMap<String, SourceFolder> new(), toCompile)

        for(candidate in toCompile) {
            CGenerator new(params, candidate) write()
        }

        params libcachePath = params outPath path
        copyLocals(module, params)

        params libcachePath = originalOutPath path
        params libcache = true
        flags := Flags new(null, params)

        // we'll do that ourselves
        flags doTargetSpecific = false

        // we'll handle the GC flags ourselves, thanks
        enableGC := params enableGC
        params enableGC = false
        flags absorb(params)
        params enableGC = enableGC

        for (sourceFolder in sourceFolders) {
            flags absorb(sourceFolder)
        }

        for (module in toCompile) {
            flags absorb(module)
        }
        params libcache = false

        // do the actual writing
        mw := CMakefileWriter new(params, makefile, flags, toCompile, module, originalOutPath)
        mw write()
        mw close()

        return 0

    }

}

CMakefileWriter: class {

    file: File
    flags: Flags
    params: BuildParams
    tw: TabbedWriter
    toCompile: ArrayList<Module>
    module: Module
    originalOutPath: File

    init: func (=params, =file, =flags, =toCompile, =module, =originalOutPath) {
        tw = TabbedWriter new(FileWriter new(file))
    }

    write: func {
        "Writing to %s" printfln(file path)
        writePrelude()
        writeBasicConfig()
        writeProject()
        writePkgConfig()
        writeThreadFlags()
        writeBasicFlags()
        writeFlags()
        writeIncludes()
        writeSources()
        writeExecutable()
    }

    writePrelude: func {
        tw writeln("# CMakeLists.txt generated by rock, the ooc compiler written in ooc")
        tw writeln("# See https://github.com/fasterthanlime/rock and http://ooc-lang.org")
        tw nl()
    }

    writeBasicConfig: func{
        tw writeln("cmake_minimum_required (VERSION 2.6)")
        tw nl()
        tw writeln("ENABLE_LANGUAGE(C)")
        tw nl()
    }

    writePkgConfig: func {
        tw writeln("include(FindPkgConfig)")
    }

    writeThreadFlags: func {
        tw writeln("find_package (Threads)")
        tw writeln("set(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} ${Threads_INCLUDE_DIRS}\")")
        tw writeln("if(CMAKE_USE_PTHREADS_INIT)")
        tw writeln("  set(CMAKE_EXE_LINKER_FLAGS \"${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_THREAD_LIBS_INIT}\")")
        tw writeln("endif(CMAKE_USE_PTHREADS_INIT)")
        tw nl()
    }

    writeBasicFlags: func {

        tw writeln("set(CMAKE_C_FLAGS_DEBUG \"-g -O0 -fno-inline ${CMAKE_C_FLAGS_DEBUG}\")")
        tw writeln("set(CMAKE_C_FLAGS_RELEASE \"-O3 ${CMAKE_C_FLAGS_RELEASE}\")")
    }

    writeFlags: func {
        tw writeln("if(CMAKE_SIZEOF_VOID_P EQUAL 8)")
        tw writeln("    set(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} -m64\")")
        tw writeln("else()")
        tw writeln("    set(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} -m32\")")
        tw writeln("endif()")
        tw nl()

        tw write("set(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} -I/usr/pkg/include")
        for (flag in flags compilerFlags) {
            tw write(" "). write(flag)
        }
        tw writeln("\")")
        tw nl(). nl()

        tw write("SET(CMAKE_EXE_LINKER_FLAGS \"${CMAKE_EXE_LINKER_FLAGS} -L/usr/pkg/lib")
        for(dynamicLib in params dynamicLibs) {
            tw write(" -l "). write(dynamicLib)
        }

        for(libPath in params libPath getPaths()) {
            tw write(" -L "). write(libPath getPath())
        }

        for(linkerFlag in flags linkerFlags) {
            tw write(" "). write(linkerFlag)
        }
        tw write("\")")
        tw nl(). nl()

        targets := HashMap<Int, String> new()
        targets put(Target LINUX, "Linux")
        targets put(Target WIN, "WIN32")
        targets put(Target OSX, "APPLE")
        targets each(|target, name|
            if(Target LINUX == target){
                tw writeln("IF(CMAKE_SYSTEM_NAME STREQUAL Linux)")
                tw write("\tmessage(STATUS \"Found System: ").
                    write(name).
                    writeln("\")")
                for (useDef in flags uses) {
                    writeUseDef(useDef getPropertiesForTarget(target))
                }
                tw writeln("ENDIF(CMAKE_SYSTEM_NAME STREQUAL Linux)")
                return
            }
            tw write("IF("). write(name). writeln(")")
            tw write("\tmessage(STATUS \"Found System: ").
                write(name).
                writeln("\")")
            for (useDef in flags uses) {
                writeUseDef(useDef getPropertiesForTarget(target))
            }
            tw write("ENDIF("). write(name). write(")"). nl(). nl()
        )

        if(params enableGC) {
            tw writeln("pkg_check_modules(GC REQUIRED bdw-gc)")
            tw writeln("link_directories(${GC_LIBRARY_DIRS})")
            tw writeln("# If there's a threaded version, use it")
            tw writeln("find_library(LIBGC gc-threaded PATHS ${GC_LIBRARY_DIRS})")
            tw writeln("if (LIBGC)")
            tw writeln("else ()")
            tw writeln("	find_library(LIBGC gc PATHS GC_LIBRARY_DIRS)")
            tw writeln("endif ()")
            tw writeln("message(STATUS \"Using Boehm GC library: ${LIBGC}\")")
            tw writeln("include_directories(${GC_INCLUDE_DIRS})")
            tw writeln("set(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} ${GC_CFLAGS}\")")
            tw write("SET(CMAKE_EXE_LINKER_FLAGS \"${CMAKE_EXE_LINKER_FLAGS} -lgc\")")

            tw nl()
        }
    }

    writeUseDef: func (props: UseProperties) {
        // cflags
        cflags  := ArrayList<String> new()
        for (path in props includePaths) {
            cflags add("-I" + path)
        }

        if (!cflags empty?()) {
            tw write("\tset(CMAKE_C_FLAGS \"${CMAKE_C_FLAGS} ")
            for (flag in cflags) {
                tw write(flag). write(" ")
            }
            tw write("\")")
            tw nl()
        }

        // ldflags
        ldflags := ArrayList<String> new()
        ldflags addAll(props libs)
        for (path in props libPaths) {
            ldflags add("-L" + path)
        }
        for (framework in props frameworks) {
            ldflags add("-Wl,-framework," + framework)
        }

        if (!ldflags empty?()) {
            tw write("\tset(CMAKE_EXE_LINKER_FLAGS \"${CMAKE_EXE_LINKER_FLAGS} ")
            for (flag in ldflags) {
                tw write(flag). write(" ")
            }
            tw writeln("\")")
            tw nl()
        }

        if(!props pkgs empty?() > 0){
            tw write("\tpkg_check_modules(pkgs REQUIRED ")
            props pkgs each(|name, value|
                tw write(name). write(" "). nl()
            )
            tw writeln(")")
        tw writeln("\tlink_directories(${pkgs_LIBRARY_DIRS})")
        tw writeln("\tinclude_directories(${pkgs_INCLUDE_DIRS})")
        tw writeln("\tset(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} ${pkgs_CFLAGS})")
        tw writeln("\tset(CMAKE_EXE_LINKER_FLAGS ${CAMKE_EXE_LINKER_FLAGS} ${pkgs_CFLAGS})")
        tw nl()
        }

        if(!props customPkgs empty?()){
            props customPkgs each(|customPkg|
                if(!customPkg names empty?()){
                    tw write("\tpkg_check_modules(custompkgs REQUIRED ")
                    for (name in customPkg names) {
                        tw write(" "). write(name)
                    }
                    tw writeln(")")
                    tw writeln("\tlink_directories(${custompkgs_LIBRARY_DIRS})")
                    tw writeln("\tinclude_directories(${custompkgs_INCLUDE_DIRS})")
                    tw writeln("\tset(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} ${custompkgs_CFLAGS})")
                    tw writeln("\tset(CMAKE_EXE_LINKER_FLAGS ${CAMKE_EXE_LINKER_FLAGS} ${custom_CFLAGS})")
                }
            )
        }
    }

    projectName: func -> String{
        projName := ""
        if(params binaryPath != "") {
            projName = params binaryPath
        } else if(!module dummy){
            projName = module simpleName
        }
        projName
    }

    writeProject: func {
        tw write("project(")
        tw write(projectName() == "" ? "dummy" : projectName())
        tw write(")")
        tw nl()
    }

    writeExecutable: func{

        if(projectName() == ""){
            tw write("add_library(")
            tw write("dummy")
        } else {
            tw write("add_executable(")
            tw write(projectName())
        }
        tw write(" ${cset_SOURCES})"). nl()
    }

    writeIncludes: func{
        tw write("set(cset_HEADERS ")
        for(currentModule in toCompile) {
            path := File new(originalOutPath, currentModule getPath("")) getPath()
            tw write(path). write(".h ").
            write(path). write("-fwd.h ")
        }
        tw writeln(")")
        tw nl()
    }

    writeSources: func{
        tw write("set(cset_SOURCES ")
        for(currentModule in toCompile) {
            if(currentModule dummy) continue
            path := File new(originalOutPath, currentModule getPath("")) getPath()
            tw write(path). write(".c ")
        }

        for (uze in flags uses) {
            props := uze getRelevantProperties(params)
            for (additional in props additionals) {
                cPath := File new(File new(originalOutPath, uze identifier), additional relative) path
                tw write(cPath). write(" ")
            }

        }
        tw writeln(")")
        tw nl()
    }

    close: func {
        tw close()
    }

}

