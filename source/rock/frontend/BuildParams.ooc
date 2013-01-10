
// sdk stuff
import io/File, os/[Env, System, ShellUtils]
import structs/[ArrayList, HashMap]
import text/StringTokenizer

// out stuff
import PathList, CommandLine
import drivers/CCompiler
import rock/middle/Module
import rock/middle/tinker/Errors

/**
 * All the parameters for a build are stored there.
 *
 * All sorts of paths and options that influence compilation.
 * This class is also responsible for finding the sdk and rock's home directory.
 *
 * :author: Amos Wenger (nddrylliog)
 */
BuildParams: class {

    errorHandler: ErrorHandler { get set }
    fatalError := true

    compilerArgs := ArrayList<String> new()

    /* Builtin defines */
    GC_DEFINE := static const "__OOC_USE_GC__"

    init: func (execName: String) {
        findDist(execName)
        findLibsPath()

        // use the GC by default =)
        defines add(This GC_DEFINE)
        // also, don't use the thread redirects by default. It causes problems on
        // mingw where the mingw definition of `_beginthreadex` gets messed up by
        // the gc's `_beginthreadex` -> `GC_beginthreadex` macro. And we don't
        // need them anyway, do we?
        defines add("GC_NO_THREAD_REDIRECTS")

        // use a simple error handler by default
        // FIXME: why the workaround :(
        errorHandler = DefaultErrorHandler new(this) as ErrorHandler
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
            distLocation = File new(realpath) getParent() getParent()
            return
        }

        // fall back on the current working directory
        file := File new(File getCwd())
        distLocation = file getParent()
        if (distLocation path empty?() || !distLocation exists?()) Exception new (This, "can not find the distribution. did you set ROCK_DIST environment variable?")
    }

    findLibsPath: func {
        // add from environment variable
        path := Env get("OOC_LIBS")
        if(path) {
            path split(File pathDelimiter, false) each(|path|
                libsPaths add(File new(path))
            )
        } else {
            addIfExists := func (path: String) {
              f := File new(path)
              if (f exists?()) {
                libsPaths add(f)
              }
            }

            addIfExists("/usr/lib/ooc")
            addIfExists("/usr/local/lib/ooc")
        }

        // add rock dist location as last element
        libsPaths add(distLocation)
    }

    // location of rock's distribution, with a libs/ folder for the gc, etc.
    distLocation: File

    // where ooc libraries live (.use)
    libsPaths := ArrayList<File> new()

    // compiler used for producing an executable from the C sources
    compiler := CCompiler new(this)

    // ooc sourcepath (.ooc)
    sourcePath := PathList new()

    // map of sourcepath elements => .use name
    sourcePathTable := HashMap<String, String> new()

    // C libraries path (.so)
    libPath := PathList new()

    // C includes path (.h)
    incPath := PathList new()

    // path to which the .c files are written
    outPath: File = File new("rock_tmp")

    // if non-null, use 'linker' as the last step of the compile process, with driver=sequence
    linker : String = null

    // threads used by the sequence driver
    parallelism := System numProcessors()

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

    // Ignore these defines when trying to determine if a cached lib is up-to-date or not
    ignoredDefines := ArrayList<String> new()

    // Tries to find types/functions in not-imported nodules, etc. Disable with -noshit
    helpful := true

    // Displays [ OK ] or [FAIL] at the end of the compilation
    shout := true

    // If false, output .o files. Otherwise output executables
    link := true

    // Run files after compilation
    run := false

    // Display compilation times for all .ooc files passed to the compiler
    timing := false

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

    // add a main method if there's none in the specified ooc file
    defaultMain := true

    // maximum number of rounds the tinkerer will do before blowing up.
    blowup := 32

    // dynamic libraries to be linked into the executable
    dynamicLibs := ArrayList<String> new()

    // backend
    backend: String = "c"

    checkBinaryNameCollision: func (name: String) {
        if (File new(name) dir?()) {
            stderr write("Naming conflict (output binary) : There is already a directory called %s.\nTry a different name, e.g. '-o=%s2'\n" format(name, name))
            CommandLine failure(this)
        }
    } 

    /**
     * :return: the path of the executable that should be produced by rock
     */
    getBinaryPath: func (defaultPath: String) -> String {
        if (binaryPath == "") {
            checkBinaryNameCollision(defaultPath)
            defaultPath
        } else {
            binaryPath
        }
    }

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
        if(!defaultMain)    b append(" -nomain")
        if(!lineDirectives) b append(" -nolines")
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
