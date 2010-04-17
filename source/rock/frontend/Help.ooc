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

        println("Usage: ooc [options] files\n")
        println(
"-v, -verbose                    verbose
-g, -debug                      compile with debug information
-noclean                        don't delete any temporary file produced by
                                the backend
-backend=[c,json]               choose the rock backend (default=c)
-gcc,-tcc,-icc,-clang,-onlygen  choose the compiler backend (default=gcc)
-onlygen doesn't launch any C compiler, and implies -noclean
-gc=[dynamic,static,off]        link dynamically, link statically, or doesn't
                                link with the Boehm GC at all.
-driver=[combine,sequence]      choose the driver to use. combine does all in one,
                                sequence does all the .c one after the other.
-sourcepath=output/path/        location of your source files
-outpath                        where to output the  c/ h files
-Ipath, -incpath=path           where to find C headers
-Lpath, -libpath=path           where to find libraries to link with
-lmylib                         link with library 'mylib'
-timing                         print how much time it took to compile
-r, -run                        runs the executable after compilation
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
