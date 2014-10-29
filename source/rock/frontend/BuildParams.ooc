
// sdk stuff
import io/File, os/[Env, System, ShellUtils]
import structs/[ArrayList, HashMap]
import text/StringTokenizer

// out stuff
import PathList, CommandLine, Target
import drivers/CCompiler
import rock/middle/[Module, UseDef]
import rock/middle/tinker/Errors
import rock/frontend/drivers/[Driver, SequenceDriver]

/**
 * All the parameters for a build are stored there.
 *
 * All sorts of paths and options that influence compilation.
 * This class is also responsible for finding the sdk and rock's home directory.
 */
BuildParams: class {

    errorHandler: ErrorHandler { get set }
    fatalError := true

    compilerArgs := ArrayList<String> new()

    /* Builtin defines */
    GC_DEFINE := static const "__OOC_USE_GC__"
    DEBUG_DEFINE := static const "__OOC_DEBUG__"

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

        doTargetSpecific()
    }

    // handle with care.
    init: func ~empty

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
            path split(File pathDelimiter, false) each(|libPath|
                libsPaths add(File new(libPath))
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

    // GNU ar program to use
    ar := "ar"

    // library type when compile from dummy module
    staticLib := false

    // host value for the toolchain, for example 'i586-mingw32msvc'
    host := ""

    // compiler flags that should never be used, ever.
    bannedFlags := ArrayList<String> new()

    // ooc sourcepath (.ooc)
    sourcePath := PathList new()

    // map of sourcepath elements => UseDef(s)
    sourcePathTable := HashMap<String, UseDef> new()

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

    // Profile - debug by default, use `-pr` for release profile
    profile := Profile DEBUG

    // Optimization level
    optimization := OptimizationLevel O0

    // Do inlining
    inlining := false

    // Display compilation progress info
    verbose := false

    // Displays which files it parses, and a few debug infos
    verboser := false

    // Display compilation statistics
    stats := false

    // More debug messages
    veryVerbose := false

    // Debugging purposes
    debugLoop := false
    debugLibcache := false
    debugTemplates := false

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

    // target
    target := Target guessHost()

    // compilation driver
    driver := SequenceDriver new(this)

    validBinaryName?: func (name: String) -> Bool {
        if (File new(name) dir?()) {
            stderr write("Naming conflict (output binary) : There is already a directory called %s.\nTry a different name, e.g. '-o=%s2'\n" format(name, name))
            false
        } else {
            true
        }
    }

    /**
     * @return the path of the executable that should be produced by rock
     */
    getBinaryPath: func (defaultPath: String) -> String {
        if (target == Target WIN) {
            defaultPath = defaultPath + ".exe"
        }

        if (binaryPath == "") {
            if (!validBinaryName?(defaultPath)) {
                return null
            }
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

    undoTargetSpecific: func {
        // there's really nothing to do here..
    }

    doTargetSpecific: func {
        match target {
            case Target WIN =>
                // on Windows, we never use pthreads
                bannedFlags add("-pthread")
            case Target OSX =>
                // on OSX, make universal binaries
                arch = "universal"
        }
    }

    getArch: func -> String {
        if (arch == "") {
            Target getArch()
        } else {
            arch
        }
    }

    // adjust consequences of high level parameters like profile, host, etc.
    bake: func {
        match profile {
            case Profile DEBUG =>
                // don't clean on debug
                clean = false
                // define debug symbol
                defineSymbol(This DEBUG_DEFINE)
            case Profile RELEASE =>
                // optimize on release
                optimization = OptimizationLevel O3
        }

        if (host != "") {
            tokens := host split('-')
            if (tokens size < 2) {
                ParamsError new("Invalid host value: %s" format(host)) throw()
            }

            (archToken, targetToken) := (tokens[0], tokens[1])
            thirdToken := ""
            if (tokens size >= 3) {
                thirdToken = tokens[2]
            }

            match {
                case archToken contains?("64") =>
                    arch = "64"
                case archToken contains?("86") =>
                    arch = "32"
            }

            match {
                // Incomplete list, see http://git.savannah.gnu.org/cgit/libtool.git/tree/doc/PLATFORMS
                case targetToken contains?("mingw") || thirdToken contains?("mingw") =>
                    target = Target WIN
                case targetToken contains?("apple") =>
                    target = Target OSX
                case targetToken contains?("linux") =>
                    target = Target LINUX
                case targetToken contains?("freebsd") =>
                    target = Target FREEBSD
                case targetToken contains?("netbsd") =>
                    target = Target NETBSD
                case targetToken contains?("openbsd") =>
                    target = Target OPENBSD
                case targetToken contains?("solaris") =>
                    target = Target SOLARIS
            }

            undoTargetSpecific()
            doTargetSpecific()

            prefix := host + "-"
            compiler setExecutable(prefix + compiler executableName)
            ar = prefix + ar
        }
    }

    /**
     * @return true if we have the debug profile.
     */
    debug?: func -> Bool {
        profile == Profile DEBUG
    }

    getArgsRepr: func -> String {
        b := Buffer new()
        b append(arch)
        if(!defaultMain)    b append(" -nomain")
        if(!lineDirectives) b append(" -nolines")
        match profile {
            case Profile DEBUG =>
                b append(" -pg")
            case Profile RELEASE =>
                b append(" -pr")
        }
        match optimization {
            case OptimizationLevel O0 =>
                b append(" -O0")
            case OptimizationLevel O1 =>
                b append(" -O1")
            case OptimizationLevel O2 =>
                b append(" -O2")
            case OptimizationLevel O3 =>
                b append(" -O3")
            case OptimizationLevel Os =>
                b append(" -Os")
        }
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

/**
 * Profile - can be DEBUG (include debug symbols, etc.)
 * or RELEASE (no debug symbols, optimize)
 *
 * In DEBUG profile, the `debug` version blocks are activated
 * as well.
 */
Profile: enum {
    DEBUG
    RELEASE
}

/**
 * Optimization level - from 0 (no optimization) to 3 (full swing),
 * and s (optimize for size). -Os is the default on RELEASE profile.
 */
OptimizationLevel: enum {
    O0
    O1
    O2
    O3
    Os
}

ParamsError: class extends Exception {
    init: func (=message)
}

