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
"The default rock options are:
rock yourmodule.ooc -backend=c -driver=sequence -gc=static -libcache -outpath=rock_tmp/ -o=yourmodule

-v, -verbose
    Print more information during the build process, useful for
    debugging.
-vv, -veryVerbose
    Print even more information! -vv implies -v.
-g, -debug
    Compile with debug information.
-noclean
    Don't delete any temporary file produced by the backend, useful
    for debugging.
-backend=[c]
    Choose the rock backend. Currently, only the default backend c is
    supported.
-gcc,-tcc,-icc,-clang
    Choose the compiler backend. (default=gcc) Available compilers
    are the GNU Compiler Collection, TinyCC, Intel C++ Compiler and
    the LLVM's clang frontend. Also, you can pass onlygen to only
    generate the code and not to run any compiler.
-cc=[/path/to/ccompiler/binary]
    point to the C compilers executable
-gc=[dynamic,static,off]
    Link dynamically, link statically, or don't link with the boehm
    GC at all.
-driver=[combine,sequence,make,dummy]
    Choose the compile driver to use. combine compiles all C files
    combined, sequence compiles them sequentially, make creates a
    Makefile. dummy only generates the .c sources to rock_tmp/ (or whatever
    you set your -outpath to)
-onlyparse
    Only parse the given source file, fail on syntax errors only.
-onlycheck
    Parse the given source files and its dependencies, check everything,
    but don't generate C files.
-onlygen
    Equivalent to -driver=dummy. See above.
-dce
    sets dead code elimination flags on c compiler (currently gcc only)
-sourcepath=PATH
    Pass the location of your source files. (default=current
    directory)
-libcache, -nolibcache
    Use (or not) a library cache. By default, rock compiles related
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
    Don't link.
-linker=LINKER
    Use LINKER in the last step of the sequence driver.
-nomain
    Don't write a default main function.
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
    Print rock's version and exit.
-h, -help, --help
    Print this help and exit.
-Dmydefine
    sets \"mydefine\" for version blocks
-mARCH
    Specify the architecture (either 32 or 64).
+...
    Pass extra arguments to the compiler. Example: +-Wall will pass
    -Wall to gcc.
\nFor help about the backend options, run 'ooc -help-backends'"
        )
    }

}
