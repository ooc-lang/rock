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

If you give it no .ooc file, rock will attempt to find a .use file, and
compile it either as a program (if it has a 'Main: yourapp.ooc' directive)
or a library (if it only has a 'SourcePath: something' directive)

-backend=[c]
    Choose the rock backend. Currently, only the default backend c is
    supported.

-c
    Don't link.

-cc=[/path/to/ccompiler/binary]
    point to the C compilers executable

-dce
    sets dead code elimination flags on c compiler (currently gcc only)

-driver=[combine,sequence,make,dummy]
    Choose the compile driver to use. combine compiles all C files
    combined, sequence compiles them sequentially, make creates a
    Makefile. dummy only generates the .c sources to rock_tmp/ (or whatever
    you set your -outpath to)

-Dmydefine
    sets \"mydefine\" for version blocks

-editor=EDITOR
    The editor to run when an error in a ooc file was encountered.

-entrypoint=FUNC
    Use FUNC as entrypoint. (default=main)

-g, -debug
    Compile with debug information.

-gc=[dynamic,static,off]
    Link dynamically, link statically, or don't link with the boehm
    GC at all.

-gcc,-tcc,-icc,-clang
    Choose the compiler backend. (default=gcc) Available compilers
    are the GNU Compiler Collection, TinyCC, Intel C++ Compiler and
    the LLVM's clang frontend. Also, you can pass onlygen to only
    generate the code and not to run any compiler.

-h, -help, --help
    Print this help and exit.

-IPATH, -incpath=PATH
    Add PATH to the C header search path.

-libcache, -nolibcache
    Use (or not) a library cache. By default, rock compiles related
    bunches of .ooc files to a static library for further compilation
    processes speedups in the .libs/ directory. When the source files
    change, the static library will be recompiled automatically.
    However, if you want to turn off library caching for some reason,
    use this option.

-linker=LINKER
    Use LINKER in the last step of the sequence driver.

-lLIB
    Link with library LIB.

-LPATH, -libpath=PATH
    Add PATH to the C library search path.

-mARCH
    Specify the architecture (either 32 or 64).

-noclean
    Don't delete any temporary file produced by the backend, useful
    for debugging.

-nomain
    Don't write a default main function.

-nolines
    Print no lines directives to the C files.

-onlycheck
    Parse the given source files and its dependencies, check everything,
    but don't generate C files.

-onlygen
    Equivalent to -driver=dummy. See above.

-onlyparse
    Only parse the given source file, fail on syntax errors only.

-outpath=PATH
    Place all .c and .h files in PATH. (default=rock_tmp/)

-q, -quiet
    Makes rock shut up. Disables any previous shout, verbose, veryVerbose.

-r, -run
    Run the executable after a successful compilation.

-sourcepath=PATH
    Pass the location of your source files. (default=current
    directory)

-shout
    Print a big fat status indicator (usually [ OK ] or [FAIL]) when a build
    process is finished.

-v, -verbose
    Print more information during the build process, useful for
    debugging.

-vv, -veryVerbose
    Print even more information! -vv implies -v.

-V, -version, --version
    Print rock's version and exit.

+...
    Pass extra arguments to the compiler. Example: +-Wall will pass
    -Wall to gcc.

ADVANCED OPTIONS
----------------

-blowup=ROUNDS
    Terminate rock after ROUNDS tinkerer rounds. (default=32)

-t, -timing
    Print how much time the compilation took.
"
        )
    }

}
