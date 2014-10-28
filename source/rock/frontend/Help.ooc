/**
 * Contain the online (rather inline) help of the ooc compiler
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

--allerrors
    Attempt to display all compilation errors instead of stopping after
    the first one. The reason this is optional is because the output of
    allerrors is sometimes not so helpful. You might want to pipe it to less :)

--backend=[c,json,luaffi]
    Choose the rock backend. By default, the 'c' backend is used. 'json'
    generates a JSON representation of the AST, and 'luaffi' generate .lua
    boilerplate to help using ooc module from Lua with ooc-lua.

-c
    Don't link.

--cc=[/path/to/ccompiler/binary]
    point to the C compilers executable

--driver=[combine,sequence,make,cmake,dummy]
    Choose the compile driver to use. combine compiles all C files
    combined, sequence compiles them sequentially, make creates a
    Makefile, cmake creates a CMakeList.txt for CMake. dummy only 
    generates the .c sources to rock_tmp/ (or whatever you set your
    -outpath to)

-Dmydefine
    sets \"mydefine\" for version blocks

--editor=EDITOR
    The editor to run when an error in a ooc file was encountered.

--entrypoint=FUNC
    Use FUNC as entrypoint. (default=main)

-pg
    Use the 'debug profile' - compile with debug information and no optimization.

-pr
    Use the 'release profile' - produce optimized code.

-O0, -O1, -O2, -O3, -Os
    Choose an optimization level

--gc=[dynamic,static,off]
    Link dynamically, link statically, or don't link with the boehm
    GC at all.

-h, --help
    Print this help and exit.

-IPATH, -incpath=PATH
    Add PATH to the C header search path.

--libcache, --nolibcache
    Use (or not) a library cache. By default, rock compiles related
    bunches of .ooc files to a static library for further compilation
    processes speedups in the .libs/ directory. When the source files
    change, the static library will be recompiled automatically.
    However, if you want to turn off library caching for some reason,
    use this option.

--libs=path/to/libs
    Specify the path where you keep all your ooc libraries, with .use files
    in them so it's easy to use them! You can also use the OOC_LIBS environment
    variable.

--linker=LINKER
    Use LINKER in the last step of the sequence driver.

-lLIB
    Link with library LIB.

-LPATH, -libpath=PATH
    Add PATH to the C library search path.

--mARCH
    Specify the architecture (either 32 or 64).

--noclean
    Don't delete any temporary file produced by the backend, useful
    for debugging.

--nohints
    Don't even try to be helpful, ie. give hints when it encounters an error.
    Use it if you're so ass-tight you can't even take a little hint once in a while.

--nomain
    Don't write a default main function.

--nolines
    Print no lines directives to the C files. Use it if you want to debug
    using .c files line numbers, not .ooc files line numbers.

--onlycheck
    Parse the given source files and its dependencies, check everything,
    but don't generate C files.

--onlygen
    Equivalent to -driver=dummy. See above.

--onlyparse
    Only parse the given source file, fail on syntax errors only.

--outpath=PATH
    Place all .c and .h files in PATH. (default=rock_tmp/)

-q, --quiet
    Makes rock shut up. Disables any previous shout, verbose, veryVerbose.

-r, --run
    Run the executable after a successful compilation.

--shout
    Print a big fat status indicator (usually [ OK ] or [FAIL]) when a build
    process is finished.

--sourcepath=PATH
    Pass the location of your source files. (default=current
    directory)

-v, --verbose
    Print more information during the build process, useful for
    debugging.

-vv, --veryVerbose
    Print even more information! -vv implies -v.

-V, --version
    Print rock's version and exit.

+...
    Pass extra arguments to the compiler. Example: +-Wall will pass
    -Wall to gcc.

ADVANCED OPTIONS
----------------

--blowup=ROUNDS
    Terminate rock after ROUNDS tinkerer rounds. (default=32)

--ignoredefine=SYMBOL
    rock remembers command-line options to know if it has to recompile some files. But
    some symbols, e.g. -DBUILD_DATE and stuff like this, shouldn't count when evaluating
    if a recompile is needed, because they change all the time. Use ignoredefine to
    ignore them when comparing build states.

--debuglibcache
    Print debug message about libcache (might help in case of weird C compiler errors
    about missing files and the such)

--debugloop
    Print debug messages about the resolving loop (might help in case of blowup)

--inline
    Enable generic inlining (EXPERIMENTAL, it will eat your dog)

--libcachepath=path
    Specify an explicit path where to store libcache files

--newstr
    Use the String class to store normal string literals, not C strings

--no-inline
    Disable generic inlining

--nolang
    Don't include 'lang/' by default. Here be dragons!

-t, --timing
    Print how much time the compilation took.
"
        )
    }

}
