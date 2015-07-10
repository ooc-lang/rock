
// sdk stuff
import io/File, os/[Terminal, Process, Pipe, Time]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

// our stuff
import Help, Token, BuildParams, AstBuilder, PathList, Target
import rock/frontend/drivers/[Driver, SequenceDriver, MakeDriver, DummyDriver, CCompiler, AndroidDriver, CMakeDriver]
import rock/backend/json/JSONGenerator
import rock/backend/lua/LuaGenerator
import rock/middle/[Module, Import, UseDef, Use]
import rock/middle/tinker/Tinkerer
import rock/middle/algo/ImportClassifier
import rock/RockVersion

system: extern func (command: CString)

/**
 * Handles command-line arguments parsing, launches the appropritae
 * driver.
 */

CommandLine: class {

    params: BuildParams
    mainUseDef: UseDef

    init: func(args : ArrayList<String>) {

        params = BuildParams new(args[0])

        modulePaths := ArrayList<String> new()
        isFirst := true
        alreadyDidSomething := false
        targetModule: Module

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
                    "[ERROR] Specifying sourcepath by hand is deprecated.\nInstead, create a .use file and specify the sourcepath from there." println()
                    hardDeprecation("staticlib")
                } else if (option startsWith?("outpath=")) {

                    if(!longOption) warnUseLong("outpath")
                    params outPath = File new(arg substring(arg indexOf('=') + 1))
                    params clean = false

                } else if (option startsWith?("staticlib")) {
                    hardDeprecation("staticlib")
                } else if (option startsWith?("dynamiclib")) {
                    hardDeprecation("dynamiclib")
                } else if (option startsWith?("packagefilter=")) {
                    hardDeprecation("packagefilter")
                } else if (option startsWith?("libfolder=")) {
                    hardDeprecation("libfolder")
                } else if(option startsWith?("backend")) {

                    if(!longOption) warnUseLong("backend")
                    params backend = arg substring(arg indexOf('=') + 1)

                    if(params backend != "c" && params backend != "json" && params backend != "luaffi") {
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

                    hardDeprecation("newsdk")

                } else if (option == "newstr") {

                    hardDeprecation("newstr")

                } else if(option == "cstrings") {

                    hardDeprecation("cstrings")

                } else if (option == "inline") {

                    hardDeprecation("inline")

                } else if (option == "no-inline") {

                    hardDeprecation("inline")

                } else if (option == "c") {

                    params link = false

                } else if(option == "debugloop") {

                    if(!longOption) warnUseLong("debugloop")
                    params debugLoop = true

                } else if(option == "debuglibcache") {

                    if(!longOption) warnUseLong("debuglibcache")
                    params debugLibcache = true

                } else if (option == "debugtemplates") {

                    if(!longOption) warnUseLong("debugtemplates")
                    params debugTemplates = true

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

                } else if(option startsWith?("use=")) {
                    
                    if (!longOption) warnUseLong("use")
                    params builtinUses add(option substring(4))

                } else if(option startsWith?("linker=")) {

                    if(!longOption) warnUseLong("linker")
                    params linker = option substring(7)

                } else if (option == "nolibcache") {

                    hardDeprecation("nolibcache")

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

                    warnDeprecated(option, "pg")
                    params profile = Profile DEBUG

                } else if (option == "pg") {

                    params profile = Profile DEBUG

                } else if (option == "pr") {

                    params profile = Profile RELEASE

                } else if (option == "O0") {

                    params optimization = OptimizationLevel O0

                } else if (option == "O1") {

                    params optimization = OptimizationLevel O1

                } else if (option == "O2") {

                    params optimization = OptimizationLevel O2

                } else if (option == "O3") {

                    params optimization = OptimizationLevel O3

                } else if (option == "Os") {

                    params optimization = OptimizationLevel Os

                } else if (option == "verbose" || option == "v") {

                    if(!longOption && option != "v") warnUseLong("verbose")
                    params verbose = true

                } else if (option == "verboser" || option == "vv") {

                    if(!longOption && option != "vv") warnUseLong("verbose")
                    params verbose = true
                    params verboser = true

                } else if (option == "veryVerbose" || option == "vvv") {

                    if(!longOption && option != "vvv") warnUseLong("veryVerbose")
                    params verbose = true
                    params verboser = true
                    params veryVerbose = true

                } else if (option == "stats") {

                    if(!longOption) warnUseLong("stats")
                    params stats = true

                } else if (option == "run" || option == "r") {

                    if(!longOption && option != "r") warnUseLong("run")
                    params run = true
                    params shout = false

                } else if (option startsWith?("target=")) {

                    targetName := option substring("target=" length())
                    params target = match targetName {
                        case "linux" => Target LINUX
                        case "win" => Target WIN
                        case "solaris" => Target SOLARIS
                        case "haiku" => Target HAIKU
                        case "osx" => Target OSX
                        case "freebsd" => Target FREEBSD
                        case "openbsd" => Target OPENBSD
                        case "netbsd" => Target NETBSD
                        case "dragonfly" => Target DRAGONFLY
                        case "android" => Target ANDROID
                        case =>
                            "[ERROR] Unknown target: %s" printfln(targetName)
                            failure(params)
                            -1
                    }
                    params undoTargetSpecific()
                    params doTargetSpecific()

                } else if (option startsWith?("driver=")) {

                    driverName := option substring("driver=" length())
                    params driver = match (driverName) {
                        case "combine" =>
                            "[ERROR] The combine driver is deprecated." println()
                            failure(params)
                            params driver
                        case "sequence" =>
                            SequenceDriver new(params)
                        case "android" =>
                            params target = Target ANDROID
                            AndroidDriver new(params)
                        case "make" =>
                            MakeDriver new(params)
                        case "cmake" =>
                            CMakeDriver new(params)
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

                } else if (option startsWith?("cc=")) {

                    if(!longOption) warnUseLong("cc")
                    params compiler setExecutable(option substring(3))

                } else if (option startsWith?("host=")) {

                    host := option substring("host=" length())
                    params host = host

                } else if (option startsWith?("gcc")) {

                    hardDeprecation("gcc")

                } else if (option startsWith?("icc")) {

                    hardDeprecation("icc")

                } else if (option startsWith?("tcc")) {

                    hardDeprecation("tcc")

                } else if (option startsWith?("clang")) {

                    hardDeprecation("clang")

                } else if (option == "onlyparse") {

                    if(!longOption) warnUseLong("onlyparse")
                    params driver = null
                    params onlyparse = true

                } else if (option == "onlycheck") {

                    if(!longOption) warnUseLong("onlycheck")
                    params driver = null

                } else if (option == "onlygen") {

                    if(!longOption) warnUseLong("onlygen")
                    params driver = DummyDriver new(params)

                } else if (option startsWith?("o=")) {

                    params binaryPath = arg substring(arg indexOf('=') + 1)

                } else if (option == "slave") {

                    hardDeprecation("slave")

                } else if (option startsWith?("bannedflag=")) {

                    flag := arg substring(arg indexOf('=') + 1)
                    params bannedFlags add(flag)

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
                    alreadyDidSomething = true

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
                        prepareCompilationFromUse(File new(arg), modulePaths, true, targetModule&)
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

        try {
            params bake()
        } catch (e: ParamsError) {
            error(e message)
            failure(params)
        }

        if(modulePaths empty?() && !targetModule) {
            if (alreadyDidSomething) {
                exit(0)
            }
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

            prepareCompilationFromUse(uzeFile, modulePaths, false, targetModule&)
        }

        if(params sourcePath empty?()) {
            moduleName := "program"
            if (!modulePaths empty?()) {
              moduleName = modulePaths get(0)
            }

            if (moduleName endsWith?(".ooc")) {
              moduleName = moduleName[0..-5]
            }

            virtualUse := UseDef new(moduleName)
            virtualUse sourcePath = File new(".") getAbsolutePath()
            virtualUse apply(params)
        }

        errorCode := 0

        if (targetModule) {
            postParsing(targetModule)
        } else for(modulePath in modulePaths) {
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

    prepareCompilationFromUse: func (uzeFile: File, modulePaths: ArrayList<String>, crucial: Bool, targetModule: Module@) {
        // extract '.use' from use file
        identifier := uzeFile name[0..-5]
        uze := UseDef new(identifier)
        mainUseDef = uze
        uze read(uzeFile, params)
        if(uze main) {
            // compile as a program
            uze apply(params)
            modulePaths add(uze main)
        } else {
            // compile as a library
            if (params verbose) {
                "Compiling '%s' as a library" printfln(identifier)
            }
            uze apply(params)

            if (!uze sourcePath) {
                error("No SourcePath directive in '%s'" format(uzeFile path))
                failure(params)
            }

            params link = false

            base := File new(uze sourcePath)
            if (!base exists?()) {
                error("SourcePath '%s' doesn't exist" format(base path))
                failure(params)
            }

            importz := ArrayList<String> new()
            base walk(|f|
                if (f file?() && f path toLower() endsWith?(".ooc")) {
                    importz add(f rebase(base) path[0..-5])
                }
                true
            )

            fullName := ""
            module := Module new(fullName, uze sourcePath, params, nullToken)
            module token = nullToken
            module token module = module
            module lastModified = uzeFile lastModified()
            module dummy = true
            for (importPath in importz) {
                imp := Import new(importPath, module token)
                module addImport(imp)
            }

            targetModule = module
        }
    }

    clean: func {
        params outPath rm_rf()
    }

    cleanHardcore: func {
        clean()
        File new(params libcachePath) rm_rf()
    }

    parse: func (moduleName: String) -> Int {
        (moduleFile, pathElement) := params sourcePath getFile(moduleName)
        if(!moduleFile) {
            "[ERROR] Could not find main .ooc file: %s" printfln(moduleName)
            "[INFO] SourcePath = %s" printfln(params sourcePath toString())
            failure(params)
            exit(1)
        }

        modulePath := moduleFile path
        fullName := moduleName[0..-5] // strip the ".ooc"
        module := Module new(fullName, pathElement path, params, nullToken)
        module token = nullToken
        module token module = module
        module main = true
        for (uze in params builtinUses) {
            module addUse(Use new(uze, params, module token))
        }
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
            success(params)
            return
        }

        parseMs := Time measure(||
            module parseImports(null)
        )
        if (params timing) {
            "Parsing took %d ms" printfln(parseMs)
        }

        if(params verbose) {
            "Resolving..." println()
        }

        // phase 2: tinker
        allModules := module collectDeps()
        resolveMs := Time measure(||
            if(!Tinkerer new(params) process(allModules)) {
                failure(params)
            }
        )
        if (params timing) {
            "Resolving took %d ms" printfln(resolveMs)
        }

        // phase 2bis: classify imports
        for (module in allModules) {
            ImportClassifier classify(module)
        }

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(params driver != null) {
                code := 0
                compileMs := Time measure(||
                    code = params driver compile(module)
                )
                if(code == 0) {
                    if (params timing) {
                        "C generation & compiling took %d ms" printfln(compileMs)
                    }
                    success(params)
                    if(params run) {
                        // FIXME: that's the driver's job
                        if(params binaryPath && !params binaryPath empty?()) Process new(["./" + params binaryPath]) execute()
                        else Process new(["./" + module simpleName]) execute()
                    }
                } else {
                    failure(params)
                }
            }

            if (mainUseDef && mainUseDef luaBindings) {
                // generate lua stuff!
                params clean = false // --backend=luaffi implies -noclean
                params outPath = File new(mainUseDef file parent, mainUseDef luaBindings)

                if (params verbose) {
                    "Writing lua bindings to #{params outPath path}" println()
                }

                for(candidate in module collectDeps()) {
                    LuaGenerator new(params, candidate) write() .close()
                }
            }
        } else if(params backend == "json") {
            // json phase 3: generate.
            params clean = false // --backend=json implies -noclean
            for(candidate in module collectDeps()) {
                JSONGenerator new(params, candidate) write() .close()
            }
        } else if(params backend == "luaffi") {
            // generate lua stuff!
            params clean = false // --backend=luaffi implies -noclean
            for(candidate in module collectDeps()) {
                LuaGenerator new(params, candidate) write() .close()
            }
        }

        first = false
    }

    warn: static func (message: String) {
        Terminal setFgColor(Color yellow)
        "[WARN ] %s" printfln(message)
        Terminal reset()
    }

    error: static func (message: String) {
        Terminal setFgColor(Color red)
        "[ERROR] %s" printfln(message)
        Terminal reset()
    }

    warnDeprecated: static func (old, instead: String) {
        warn("Option -%s is deprecated, use -%s instead." format(old, instead))
    }

    warnUseLong: static func (option: String) {
        warn("Option -%s is deprecated, use --%s instead." format(option, option))
    }

    hardDeprecation: static func (parameter: String) {
        error("%s parameter is deprecated" format(parameter))
    }

    success: static func (params: BuildParams) {
        if (params shout) {
            Terminal setAttr(Attr bright)
            Terminal setFgColor(Color green)
            "[ OK ]" println()
            Terminal reset()
        }
    }

    failure: static func (params: BuildParams) {
        if (params shout) {
            Terminal setAttr(Attr bright)
            Terminal setFgColor(Color red)
            "[FAIL]" println()
            Terminal reset()
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

