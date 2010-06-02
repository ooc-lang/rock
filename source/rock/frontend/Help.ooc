/**
 * Contain the online (rather inline) help of the ooc compiler
 * 
 * @author Amos Wenger
 */
Help: class {

    /**
     * Print a helpful help message that helps 
     */
    printHelp: static func {

        println("Usage: rock [options] files\n")
        println(
"-v, -verbose
    Print more information during the build process, useful for
    debugging.
-vv, -veryVerbose
    Print even more information! -vv implies -v.
-g, -debug
    Compile with debug information.
-noclean
    Don’t delete any temporary file produced by the backend, useful
    for debugging.
-backend=[c]
    Choose the rock backend. Currently, only the default backend c is
    supported.
-gcc,-tcc,-icc,-clang,-onlygen
    Choose the compiler backend. (default=gcc) Available compilers
    are the GNU Compiler Collection, TinyCC, Intel C++ Compiler and
    the LLVM’s clang frontend. Also, you can pass onlygen to only
    generate the code and not to run any compiler.
-gc=[dynamic,static,off]
    Link dynamically, link statically, or don’t link with the boehm
    GC at all.
-driver=[combine,sequence,make]
    Choose the compile driver to use. combine compiles all C files
    combined, sequence compiles them sequentially, make creates a
    Makefile.
-sourcepath=PATH
    Pass the location of your source files. (default=current
    directory)
-nolibcache
    Don’t use a library cache. By default, rock compiles related
    bunches of .ooc files to a static library for further compilation
    processes speedups in the .libs/ directory. When the source files
    change, the static library will be recompiled automatically.
    However, if you want to turn off library caching for some reason,
    use this option.
-outpath=PATH
    Place all .c and .h files in PATH. (default=rock_tmp/)
-IPATH, -incpath=PATH
    Add PATH to the C header search path.
-LPATH, -libpath=PATH
    Add PATH to the C library search path.
-lLIB
    Link with library LIB.
-t, -timing
    Print how much time the compilation took.
-r, -run
    Run the exectuable after a successful compilation.
-editor=EDITOR
    The editor to run when an error in a ooc file was encountered.
-entrypoint=FUNC
    Use FUNC as entrypoint. (default=main)
-c
    Don’t link.
-linker=LINKER
    Use LINKER in the last step of the sequence driver.
-nomain
    Don’t write a default main function.
-nolines
    Print no lines directives to the C files.
-shout
    Print a big fat status indicator (usually [ OK ] or [FAIL]) when a build
    process is finished.
-q, -quiet
    Makes rock shut up. Disables any previous shout, verbose, veryVerbose.
-blowup=ROUNDS
    Terminate rock after ROUNDS tinkerer rounds. (default=32)
-V, -version, --version
    Print rock’s version and exit.
-h, -help, --help
    Print this help and exit.
-mARCH
    Specify the architecture (either 32 or 64).
+...
    Pass extra arguments to the compiler. Example: +-Wall will pass
    -Wall to gcc.
\nFor help about the backend options, run 'ooc -help-backends'"
        )
    }

    /**
     * Print a helpful help message that helps about backends 
     */
    printHelpBackends: static func {
        println(
"The available backends are: [none,gcc,make] and the default is gcc 
none             just outputs the  c/ h files (be sure to have a main func)
gcc              call the GNU C compiler with appropriate options
make             generate a Makefile in the default output directory (ooc_tmp)
\nFor help about a specific backend, run 'ooc -help-gcc' for example"
        )
    }
    
    /**
     * Print a helpful help message that helps about gcc 
     */
    printHelpGcc: static func {
        println(
"gcc backend options:
-clean=[yes,no]        delete (or not) temporary files  default: yes 
                       overriden by the global option -noclean
-verbose=[yes,no]      print the gcc command lines called from the backend 
                       overriden by the global options -v, -verbose
-shout=[yes,no], -s    prints a big fat [ OK ] at the end of the compilation
                       if it was successful (in green, on Linux platforms)
any other option       passed to gcc\n"
        )
    }
    
    /**
     * Print a helpful help message that helps about make 
     */
    printHelpMake: static func {
        println(
"make backend options:
-cc=[gcc,icl]        write a Makefile to be compatible with the said compiler
-link=libname a      link with the static library libname a
any other option     passed to the compiler\n"
        )
    }
    
}
