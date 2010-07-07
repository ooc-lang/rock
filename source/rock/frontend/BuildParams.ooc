import io/File, os/Env, text/Buffer
import structs/ArrayList

import compilers/AbstractCompiler
import PathList, rock/rock, rock/utils/ShellUtils
import ../middle/Module

BuildParams: class {

    fatalError := static true

    additionals  := ArrayList<String> new()
    compilerArgs := ArrayList<String> new()

    /* Builtin defines */
	GC_DEFINE := static const "__OOC_USE_GC__"

    init: func {
        findDist()
        findSdk()
        findLibsPath()

        // use the GC by default =)
		defines add(This GC_DEFINE)
    }

    findDist: func {
        // specified by command-line?
        if(distLocation) return

        env := Env get("ROCK_DIST")
        if(!env) {
            env = Env get("OOC_DIST")
        }

        if (env) {
            distLocation = File new(env trimRight(File separator))
            return
        }

        // fall back to ../../ from the executable
        // e.g. if rock is in /opt/ooc/rock/bin/rock
        // then it will set dist to /opt/ooc/rock/
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            distLocation = File new(realpath) parent() parent()
            return
        }

        // fall back on the current working directory
        file := File new(File getCwd())
        distLocation = file parent()
    }

    findSdk: func {
        // specified by command-line?
        if(sdkLocation) return

        env := Env get("ROCK_SDK")
        if(!env) {
            env = Env get("OOC_SDK")
        }

        if (env) {
            sdkLocation = File new(env trimRight(File separator))
            return
        }

        // fall back to dist + sdk/
        sdkLocation = File new(distLocation, "sdk")
    }

    findLibsPath: func {
        // specified by command-line?
        if(libsPath) return

        // find libsPath
        path := Env get("OOC_LIBS")
        if(path == null) {
            // TODO: find other standard paths for other OSes
            path = "/usr/lib/ooc/"
        }
        libsPath = File new(path)
    }

    // location of the compiler's distribution, with a libs/ folder for the gc, etc.
    distLocation: File

    // location of the ooc SDK, with the basic classes, lang/, structs/, io/
    sdkLocation: File

    // where ooc libraries live (.use)
    libsPath: File

    // compiler used for producing an executable from the C sources
    compiler: AbstractCompiler = null

    // ooc sourcepath (.ooc)
    sourcePath := PathList new()

    // C libraries path (.so)
    libPath := PathList new()

    // C includes path (.h)
    incPath := PathList new()

    // path to which the .c files are written
    outPath: File = File new("rock_tmp")

    // if non-null, use 'linker' as the last step of the compile process, with driver=sequence
	linker := null as String

    // threads used by the sequence driver
    sequenceThreads := 1

    // if true, only parse the given module
    onlyparse := false

    // list of symbols defined e.g. by -Dblah
	defines := ArrayList<String> new()

    // Path to place the binary
    binaryPath: String = ""

    // Path of the text editor to run when an error is encountered in an ooc file
    editor: String = ""

    // Remove the rock_tmp/ directory after the C compiler has finished
    clean := true

    // Cache libs in `libcachePath` directory
    libcache := true

    // Path to store cache-libs
    libcachePath := ".libs"

    // Add debug info to the generated C files (e.g. -g switch for gcc)
    debug := false

    // Displays which files it parses, and a few debug infos
    verbose := false

    // Display compilation statistics
    stats := false

    // More debug messages
    veryVerbose := false

    // Debugging purposes
    debugLoop := false
    debugLibcache := false

    // Ignore these defines when trying to determie if a cached lib is up-to-date or not
    // used for BUILD_DATE or BUILD_TIME stuff
    ignoredDefines := ArrayList<String> new()

    // Tries to find types/functions in not-imported nodules, etc. Disable with -noshit
    helpful := true

    // Displays [ OK ] or [FAIL] at the end of the compilation
    //shout := false
    shout := true // true as long as we're debugging

    // If false, output .o files. Otherwise output exectuables
    link := true

    // Run files after compilation
    run := false

    // Display compilation times for all .ooc files passed to the compiler
    timing := false

    // Compile once, then wait for the user to press enter, then compile again, etc.
    slave := false

    // Should link with libgc at all.
    enableGC := true

    // link dynamically with libgc (Boehm)
    dynGC := false

    // add #line directives in the generated .c for debugging.
    // depends on "debug" flag
    lineDirectives := true

    // either "32" or "64"
    arch: String = ""

    // name of the entryPoint to the program
    entryPoint := "main"

    // if non-null, will create a static library with 'ar rcs <outlib> <all .o files>'
	outlib := null as String

    // add a main method if there's none in the specified ooc file
	defaultMain := true

    // maximum number of rounds the {@link Tinkerer} will do before blowing up.
    blowup: Int = 32

    // include or not lang/ packages (for testing)
    includeLang := true

    // dynamic libraries to be linked into the executable
    dynamicLibs := ArrayList<String> new()

    // backend; can be "c" or "json".
    backend: String = "c"

    _indexOfSymbol: func (symbol: String) -> Int {
        for(i in 0..defines size()) {
            if(defines[i] == symbol) {
                return i
            }
        }
        -1
    }

    isDefined: func (symbol: String) -> Bool {
        _indexOfSymbol(symbol) != -1
    }

    defineSymbol: func (symbol: String) {
		if (!isDefined(symbol)) {
            defines add(symbol)
        }
	}

	undefineSymbol: func (symbol: String) {
        idx := _indexOfSymbol(symbol)
        if (idx != -1) {
            defines removeAt(idx)
        }
	}

    getArgsRepr: func -> String {
        b := Buffer new()
        b append(arch)
        if(!defaultMain)    b append(" -nolines")
        if(!lineDirectives) b append(" -nomain")
        if(debug)           b append(" -g")
        b append(" -gc=")
        if(enableGC) {
            if(dynGC) {
                b append("dynamic")
            } else {
                b append("static")
            }
        } else {
            b append("off")
        }
        b append(" -backend="). append(backend)
        for(arg in compilerArgs) {
            ignored := false
            for(ignoredDefine in ignoredDefines) {
                if(arg startsWith("-D" + ignoredDefine)) {
                    ignored = true
                    break
                }
            }
            if(!ignored) b append(' '). append(arg)
        }
        b toString()
    }

}
