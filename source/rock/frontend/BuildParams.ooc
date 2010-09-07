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

    // Changes the way string literals are written, among other things
    // see http://github.com/nddrylliog/newsdk for more bunnies.
    newsdk := false

    // If it's true, will use String makeLiteral() to make string literals instaed of just C string literals
    newstr := true

    // dead code elimination
    dce := false

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
    linker : String = null

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

    // Do inlining
    inlining := false

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
    staticlib : String = null

    // if non-null, will create a dynamic library
    dynamiclib : String = null

    // add a main method if there's none in the specified ooc file
    defaultMain := true

    // maximum number of rounds the {@link Tinkerer} will do before blowing up.
    blowup := 32

    // include or not lang/ packages (for testing)
    includeLang := true

    // dynamic libraries to be linked into the executable
    dynamicLibs := ArrayList<String> new()

    // if non-null, rock will create a virtual module containing all ooc modules in the given path
    libfolder: String = null

    // backend; can be "c" or "json".
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
        for(define in defines) {
            ignored := false
            for(ignoredDefine in ignoredDefines) {
                if(define startsWith?(ignoredDefine)) {
                    ignored = true
                    break
                }
            }
            if(!ignored) b append(" -D"). append(define)
        }
        for(arg in compilerArgs) {
            ignored := false
            for(ignoredDefine in ignoredDefines) {
                if(arg startsWith?("-D" + ignoredDefine)) {
                    ignored = true
                    break
                }
            }
            if(!ignored) b append(' '). append(arg)
        }
        b toString()
    }

}
