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

--allerrors
    Attempt to display all compilation errors instead of stopping after
    the first one. The reason this is optional is because the output of
    allerrors is sometimes not so helpful. You might want to pipe it to less :)

-Dmydefine
    sets \"mydefine\" for version blocks

--entrypoint=FUNC
    Use FUNC as entrypoint. (default=main)

-g, --debug
    Compile with debug information.

--gcc,--tcc,--icc,--clang
    Choose the compiler backend. (default=gcc) Available compilers
    are the GNU Compiler Collection, TinyCC, Intel C++ Compiler and
    the LLVM's clang frontend. Also, you can pass onlygen to only
    generate the code and not to run any compiler.

-h, --help
    Print this help and exit.

-IPATH, -incpath=PATH
    Add PATH to the C header search path.

--libs=path/to/libs
    Specify the path where you keep all your ooc libraries, with .use files
    in them so it's easy to use them! You can also use the OOC_LIBS environment
    variable.

-lLIB
    Link with library LIB.

-LPATH, -libpath=PATH
    Add PATH to the C library search path.

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
    Place all .c and .h files in PATH. (default=snowflake/)

-q, --quiet
    Makes rock shut up. Disables any previous verbose, veryVerbose.

--sdk=path/to/sdk
    Specify an explicit path to the sdk. Use if rock cannot find it itself, and
    you're not willing to export ROCK_SDK to path/to/rock/sdk or ROCK_DIST to
    path/to/rock. The sdk should contain a few basic things in lang/

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

--debugloop
    Print debug messages about the resolving loop (might help in case of blowup)

--nolang
    Don't include 'lang/' by default. Here be dragons!

-t, --timing
    Print how much time the compilation took.
"
        )
    }

}
