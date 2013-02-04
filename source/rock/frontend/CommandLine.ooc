
// sdk stuff
import io/File, os/[Terminal, Process, Pipe]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

// our stuff
import Help, Token, BuildParams, AstBuilder, PathList
import rock/frontend/drivers/[Driver, SequenceDriver, MakeDriver, DummyDriver, CCompiler]
import rock/backend/json/JSONGenerator
import rock/middle/[Module, Import, UseDef]
import rock/middle/tinker/Tinkerer
import rock/RockVersion

system: extern func (command: CString)

/**
 * Handles command-line arguments parsing, launches the appropritae
 * driver.
 * 
 * :author: Amos Wenger (nddrylliog)
 */

CommandLine: class {

    params: BuildParams
    driver: Driver

    init: func(args : ArrayList<String>) {

        params = BuildParams new(args[0])
        driver = SequenceDriver new(params)

        modulePaths := ArrayList<String> new()
        isFirst := true

        for (arg in args) {
            if(isFirst) {
                isFirst = false
                continue
            }

            longOption := false
            if (arg startsWith?("-")) {
                option := arg substring(1)

                if (option startsWith?("-")) {
                    longOption = true
                    option = option substring(1)
                }

                if (option startsWith?("sourcepath=")) {

                    if(!longOption) warnUseLong("sourcepath")
                    sourcePathOption := arg substring(arg indexOf('=') + 1)
                    tokens := sourcePathOption split(File pathDelimiter, false)
                    for (token in tokens) {
                        // rock allows '/' instead of '\' on Win32
                        params sourcePath add(token replaceAll('/', File separator))
                    }

                } else if (option startsWith?("outpath=")) {

                    if(!longOption) warnUseLong("outpath")
                    params outPath = File new(arg substring(arg indexOf('=') + 1))
                    params clean = false

                } else if (option startsWith?("staticlib")) {
                    hardDeprecation("staticlib", params)
                } else if (option startsWith?("dynamiclib")) {
                    hardDeprecation("dynamiclib", params)
                } else if (option startsWith?("packagefilter=")) {
                    hardDeprecation("packagefilter", params)
                } else if (option startsWith?("libfolder=")) {
                    hardDeprecation("libfolder", params)
                } else if(option startsWith?("backend")) {

                    if(!longOption) warnUseLong("backend")
                    params backend = arg substring(arg indexOf('=') + 1)

                    if(params backend != "c" && params backend != "json") {
                        "Unknown backend: %s." format(params backend) println()
                        params backend = "c"
                    }

                } else if (option startsWith?("incpath=")) {

                    if(!longOption) warnUseLong("incpath")
                    params incPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith?("D")) {

                    params defineSymbol(arg substring(2))

                } else if (option startsWith?("I")) {

                    params incPath add(arg substring(2))

                } else if (option startsWith?("libpath")) {

                    if(!longOption) warnUseLong("libpath")
                    params libPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith?("editor")) {

                    if(!longOption) warnUseLong("editor")
                    params editor = arg substring(arg indexOf('=') + 1)

                } else if (option startsWith?("entrypoint")) {

                    if(!longOption) warnUseLong("entrypoint")
                    params entryPoint = arg substring(arg indexOf('=') + 1)

                } else if (option == "newsdk") {
                    hardDeprecation("newsdk", params)
                } else if (option == "newstr") {
                    hardDeprecation("newstr", params)
                } else if(option == "cstrings") {
                    hardDeprecation("cstrings", params)
                } else if (option == "inline") {

                    if(!longOption) warnUseLong("inline")
                    params inlining = true

                } else if (option == "no-inline") {

                    if(!longOption) warnUseLong("no-inline")
                    params inlining = false

                } else if (option == "c") {

                    params link = false

                } else if(option == "debugloop") {

                    if(!longOption) warnUseLong("debugloop")
                    params debugLoop = true

                } else if(option == "debuglibcache") {

                    if(!longOption) warnUseLong("debuglibcache")
                    params debugLibcache = true

                } else if(option startsWith?("ignoredefine=")) {

                    if(!longOption) warnUseLong("ignoredefine")
                    params ignoredDefines add(option substring(13))

                } else if (option == "allerrors") {

                    if(!longOption) warnUseLong("allerrors")
                    params fatalError = false

                } else if(option startsWith?("dist=")) {

                    if(!longOption) warnUseLong("dist")
                    params distLocation = File new(option substring(5))

                } else if(option startsWith?("sdk=")) {

                    "The --sdk=PATH option is deprecated." println()
                    "If you want to use your own SDK, create your own sdk.use" println()
                    "and adjust the OOC_LIBS environment variable" println()

                } else if(option startsWith?("libs=")) {

                    if(!longOption) warnUseLong("libs")
                    params libPath = File new(option substring(5))

                } else if(option startsWith?("linker=")) {

                    if(!longOption) warnUseLong("linker")
                    params linker = option substring(7)

                } else if (option == "nolibcache") {

                    hardDeprecation("nolibcache", params)

                } else if (option == "libcache") {

                    if(!longOption) warnUseLong("libcache")
                    params libcache = true
                    
                } else if (option == "libcachepath") {

                    if(!longOption) warnUseLong("libcachepath")
                    params libcachePath = option substring(option indexOf('=') + 1)

                } else if (option startsWith?("L")) {

                    params libPath add(option substring(1))

                } else if (option startsWith?("l")) {

                    params dynamicLibs add(option substring(1))

                } else if (option == "nolang") {

                    "--nolang is not supported anymore. \
                    If you want to fiddle with the SDK, make your own sdk.use" println()

                } else if (option == "nomain") {

                    if(!longOption) warnUseLong("nomain")
                    params defaultMain = false

                } else if (option startsWith?("gc=")) {

                    suboption := option substring(3)
                    match suboption {
                        case "off" =>
                            params enableGC = false
                            params undefineSymbol(BuildParams GC_DEFINE)
                        case "dynamic" =>
                            params enableGC = true
                            params dynGC = true
                            params defineSymbol(BuildParams GC_DEFINE)
                        case "static" =>
                            params enableGC = true
                            params dynGC = false
                            params defineSymbol(BuildParams GC_DEFINE)
                        case =>
                            "Unrecognized option %s." printfln(option)
                            "Valid values are gc=off, gc=dynamic, gc=static" printfln()
                    }

                } else if (option == "noclean") {

                    if(!longOption) warnUseLong("noclean")
                    params clean = false

                } else if (option == "nohints") {

                    if(!longOption) warnUseLong("nohints")
                    params helpful = false

                } else if (option == "nolines") {

                    if(!longOption) warnUseLong("inline")
                    params lineDirectives = false

                } else if (option == "shout") {

                    if(!longOption) warnUseLong("inline")
                    params shout = true

                } else if (option == "q" || option == "quiet") {

                    if(!longOption && option != "q") warnUseLong("quiet")
                    params shout = false
                    params verbose = false
                    params veryVerbose = false

                } else if (option == "timing" || option == "t") {

                    if(!longOption && option != "t") warnUseLong("timing")
                    params timing = true

                } else if (option == "debug" || option == "g") {

                    if(!longOption && option != "g") warnUseLong("debug")
                    params debug = true
                    params clean = false

                } else if (option == "verbose" || option == "v") {

                    if(!longOption && option != "v") warnUseLong("verbose")
                    params verbose = true

                } else if (option == "veryVerbose" || option == "vv") {

                    if(!longOption && option != "vv") warnUseLong("veryVerbose")
                    params verbose = true
                    params veryVerbose = true
                    params sourcePath debug = true

                } else if (option == "stats") {

                    if(!longOption) warnUseLong("stats")
                    params stats = true

                } else if (option == "run" || option == "r") {

                    if(!longOption && option != "r") warnUseLong("run")
                    params run = true
                    params shout = false

                } else if (option startsWith?("driver=")) {

                    driverName := option substring("driver=" length())
                    driver = match (driverName) {
                        case "combine" =>
                            "[ERROR] The combine driver is deprecated." println()
                            failure(params)
                            driver
                        case "sequence" =>
                            SequenceDriver new(params)
                        case "make" =>
                            MakeDriver new(params)
                        case "dummy" =>
                            DummyDriver new(params)
                        case =>
                            "[ERROR] Unknown driver: %s" printfln(driverName)
                            failure(params)
                            null
                    }

                } else if (option startsWith?("blowup=")) {

                    if(!longOption) warnUseLong("blowup")
                    params blowup = option substring(7) toInt()

                } else if (option == "V" || option == "version") {

                    if(!longOption && option != "V") warnUseLong("version")
                    "rock %s, built on %s" printfln(RockVersion getName(), __BUILD_DATETIME__)
                    exit(0)

                } else if (option == "h" || option == "help") {

                    if(!longOption && option != "h") warnUseLong("help")
                    Help printHelp()
                    exit(0)

                } else if(option startsWith?("cc=")) {

                    if(!longOption) warnUseLong("cc")
                    params compiler setExecutable(option substring(3))

                } else if (option startsWith?("gcc")) {

                    hardDeprecation("gcc", params)

                } else if (option startsWith?("icc")) {

                    hardDeprecation("icc", params)

                } else if (option startsWith?("tcc")) {

                    hardDeprecation("tcc", params)

                } else if (option startsWith?("clang")) {

                    hardDeprecation("clang", params)

                } else if (option == "onlyparse") {

                    if(!longOption) warnUseLong("onlyparse")
                    driver = null
                    params onlyparse = true

                } else if (option == "onlycheck") {

                    if(!longOption) warnUseLong("onlycheck")
                    driver = null

                } else if (option == "onlygen") {

                    if(!longOption) warnUseLong("onlygen")
                    driver = DummyDriver new(params)

                } else if (option startsWith?("o=")) {

                    params binaryPath = arg substring(arg indexOf('=') + 1)

                } else if (option == "slave") {

                    hardDeprecation("slave", params)

                } else if (option startsWith?("j")) {

                    threads := arg substring(2) toInt()
                    params parallelism = threads
    
                } else if (option startsWith?("m")) {

                    arch := arg substring(2)
                    if (arch == "32" || arch == "64")
                        params arch = arg substring(2)
                    else
                        "Unrecognized architecture: %s" printfln(arch)

                } else if (option == "x") {
                   
                    "Cleaning up outpath and .libs" println()
                    cleanHardcore()
                    exit(0)

                } else {

                    "Unrecognized option: %s" printfln(arg)

                }
            } else if(arg startsWith?("+")) {

                params compilerArgs add(arg substring(1))

            } else {
                lowerArg := arg toLower()
                match {
                    case lowerArg endsWith?(".ooc") =>
                        modulePaths add(arg)
                    case lowerArg endsWith?(".use") =>
                        prepareCompilationFromUse(File new(arg), modulePaths)
                    case lowerArg contains?(".") =>
                        // unknown file, complain
                        "[ERROR] Don't know what to do with argument %s, bailing out" printfln(arg)
                        failure(params)
                    case =>
                        // probably an ooc file without the extension
                        modulePaths add(arg + ".ooc")
                }
            }
        }

        if(modulePaths empty?()) {
            uzeFile : File = null

            // try to find a .use file
            File new(".") children each(|c|
                // anyone using an uppercase use file is a criminal anyway.
                if(c path toLower() endsWith?(".use")) {
                    uzeFile = c
                }
            )

            if(!uzeFile) {
                "rock: no .ooc nor .use files found" println()
                exit(1)
            }

            prepareCompilationFromUse(uzeFile, modulePaths)
        }

        if(params sourcePath empty?()) {
            params sourcePath add(".")

            moduleName := "program"
            if (!modulePaths empty?()) {
              moduleName = modulePaths get(0)
            }

            if (moduleName endsWith?(".ooc")) {
              moduleName = moduleName[0..-5]
            }
            params sourcePathTable put(".", moduleName)
        }

        errorCode := 0

        for(modulePath in modulePaths) {
            code := parse(modulePath replaceAll('/', File separator))
            if(code != 0) {
                errorCode = 2 // C compiler failure.
                break
            }
        }

        // c phase 5: clean up
        if(params clean) {
            clean()
        }

    }

    prepareCompilationFromUse: func (uzeFile: File, modulePaths: ArrayList<String>) {
        // extract '.use' from use file
        identifier := uzeFile name[0..-5]
        uze := UseDef new(identifier)
        uze read(uzeFile, params)
        if(uze main) {
            // compile as a program
            uze apply(params)
            modulePaths add(uze main)
        } else {
            Exception new("[stub] libfolder compilation.") throw()
        }
    }

    clean: func {
        // oh that's a hack.
        system("rm -rf %s" format(params outPath path))
    }

    cleanHardcore: func {
        clean()
        // oh that's the same hack. Someone implement File recursiveDelete() already.
        system("rm -rf %s" format(params libcachePath))
    }

    parse: func (moduleName: String) -> Int {
        (moduleFile, pathElement) := params sourcePath getFile(moduleName)
        if(!moduleFile) {
            "File not found: %s" printfln(moduleName)
            exit(1)
        }

        modulePath := moduleFile path
        fullName := moduleName[0..-5] // strip the ".ooc"
        module := Module new(fullName, pathElement path, params, nullToken)
        module token = Token new(0, 0, module)
        module main = true
        module lastModified = moduleFile lastModified()

        // phase 1: parse
        if (params verbose) {
            "Parsing..." println()
        }
        AstBuilder new(modulePath, module, params)
        postParsing(module)

        return 0
    }

    postParsing: func (module: Module) {
        first := static true

        if(params onlyparse) {
            if(params verbose) println()
            // Oookay, we're done here.
            success()
            return
        }

        module parseImports(null)
        if(params verbose) {
            "Resolving..." println()
        }

        // phase 2: tinker
        if(!Tinkerer new(params) process(module collectDeps())) {
            failure(params)
        }

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(driver != null) {
                code := driver compile(module)
                if(code == 0) {
                    if(params shout) success()
                    if(params run) {
                        // FIXME: that's the driver's job
                        Process new(["./" + module simpleName]) execute()
                    }
                } else {
                    if(params shout) {
                        failure(params)
                    }
                }
            }
        } else if(params backend == "json") {
            // json phase 3: generate.
            params clean = false // -backend=json implies -noclean
            for(candidate in module collectDeps()) {
                JSONGenerator new(params, candidate) write() .close()
            }
        }

        first = false
    }

    warnUseLong: func (option: String) {
        "[WARNING] Option -%s is deprecated, use --%s instead." printfln(option, option)
    }

    hardDeprecation: func (parameter: String, params: BuildParams) {
        "[ERROR] %s parameter is deprecated" printfln(parameter)
        failure(params)
    }

    success: static func {
        Terminal setAttr(Attr bright)
        Terminal setFgColor(Color green)
        "[ OK ]" println()
        Terminal reset()
    }

    failure: static func (params: BuildParams) {
        Terminal setAttr(Attr bright)
        Terminal setFgColor(Color red)
        "[FAIL]" println()
        Terminal reset()
        
        // compile with -Ddebug if you want rock to raise an exception here
        version(_DEBUG) {
            raise("Debugging a CommandLine failure") // for backtrace
        }

        // FIXME: should we *ever* exit(1) ?
        exit(1)
    }

}

CompilationFailedException: class extends Exception {
    init: func {
        super("Compilation failed!")
    }
}

