import io/File, os/Env
import structs/ArrayList

import compilers/AbstractCompiler
import PathList, rock/utils/ShellUtils
import ../middle/Module, ../middle/tinker/Errors

/**
 * All the parameters for a build are stored there.
 *
 * All sorts of paths and options that influence compilation.
 *
 * This class is also responsible for finding the sdk and the dist.
 *
 * @author Amos Wenger (nddrylliog)
 */
BuildParams: class {

    // use a dumb error handler by default
    errorHandler: ErrorHandler { get set }
    fatalError := true

    additionals  := ArrayList<String> new()
    compilerArgs := ArrayList<String> new()

    /* Builtin defines */
    GC_DEFINE := static const "__OOC_USE_GC__"

    init: func (execName: String) {
        findDist(execName)
        findSdk()
        sdkLocation = sdkLocation getAbsoluteFile()
        findLibsPath()

        // use the GC by default =)
        defines add(This GC_DEFINE)

        // also, don't use the thread redirects by default. It causes problems on
        // mingw where the mingw definition of `_beginthreadex` gets messed up by
        // the gc's `_beginthreadex` -> `GC_beginthreadex` macro. And we don't
        // need them anyway, do we?
        defines add("GC_NO_THREAD_REDIRECTS")

        // use a simple error handler by default
        errorHandler = DefaultErrorHandler new(this) as ErrorHandler // FIXME: why the workaround :(
    }

    findDist: func (execName: String) {
        // specified by command-line?
        if(distLocation) return

        env := Env get("ROCK_DIST")
        if(!env) {
            env = Env get("OOC_DIST")
        }

        if (env && !env empty?()) {
            distLocation = File new(env trimRight(File separator))
            return
        }

        // fall back to ../../ from the executable
        // e.g. if rock is in /opt/ooc/rock/bin/rock
        // then it will set dist to /opt/ooc/rock/
        exec := ShellUtils findExecutable(execName, false)
        if(exec && exec path != null && !exec path empty?()) {
            realpath := exec getAbsolutePath()
            distLocation = File new(realpath) parent() parent()
            return
        }

        // fall back on the current working directory
        file := File new(File getCwd())
        distLocation = file parent()
        if (distLocation path empty?() || !distLocation exists?()) Exception new (This, "can not find the distribution. did you set ROCK_DIST environment variable?")
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
        if (sdkLocation path == null || sdkLocation path empty?() || !sdkLocation exists?()) Exception new (This, "can not find the sdk. did you set ROCK_SDK environment variable?")
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

    // C libraries path (.so/.dll)
    libPath := PathList new()

    // C includes path (.h)
    incPath := PathList new()

    // path to which the .c files are written
    outPath: File = File new("snowflake")

    // if true, only parse the given module
    onlyparse := false

    // list of symbols defined e.g. by -Dblah
    defines := ArrayList<String> new()

    // Add debug info to the generated C files (e.g. -g switch for gcc)
    debug := false

    // Displays which files it parses, and a few debug infos
    verbose := false

    // More debug messages
    veryVerbose := false

    // Debugging purposes
    debugLoop := false

    // Tries to find types/functions in not-imported nodules, etc. Disable with --nohints
    helpful := true

    // add #line directives in the generated .c for debugging.
    // depends on "debug" flag
    lineDirectives := true

    // name of the entryPoint to the program
    entryPoint := "main"

    // name of the package we should only be packaging
    // modules in any other package will be ignored
    // when building static/dynamic libraries
    packageFilter : String = null

    // add a main method if there's none in the specified ooc file
    defaultMain := true

    // maximum number of rounds the Tinkerer will do before blowing up.
    blowup := 32

    // include or not lang/ packages (for testing)
    includeLang := true

    // dynamic libraries to be linked into the executable
    dynamicLibs := ArrayList<String> new()

    // if non-null, rock will create a virtual module containing all ooc modules in the given path
    libfolder: String = null

    // if true, rock will attempt to parse C headers and take symbols from there
    parseHeaders := false

    // backend: actually only "c"
    backend: String = "c"

    _indexOfSymbol: func (symbol: String) -> Int {
        for(i in 0..defines getSize()) {
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

}
