import io/File, os/[Terminal, Process]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

import rock/rock
import Help, Token, BuildParams, AstBuilder
import compilers/[Gcc, Clang, Icc, Tcc]
import drivers/[Driver, CombineDriver, SequenceDriver, MakeDriver, DummyDriver]
//import ../backend/json/JSONGenerator
import ../middle/[Module, Import]
import ../middle/tinker/Tinkerer

ROCK_BUILD_DATE, ROCK_BUILD_TIME: extern String

CommandLine: class {
    params: BuildParams
    driver: Driver

    init: func(args : ArrayList<String>) {

        params = BuildParams new()
        driver = SequenceDriver new(params)

        modulePaths := ArrayList<String> new()
        params compiler = Gcc new()

        isFirst := true

        for (arg in args) {
            if(isFirst) {
                isFirst = false
                continue
            }

            if (arg startsWith("-")) {
                option := arg substring(1)

                if (option startsWith("sourcepath")) {

                    sourcePathOption := arg substring(arg indexOf('=') + 1)
                    tokenizer := StringTokenizer new(sourcePathOption, File pathDelimiter)
                    for (token: String in tokenizer) {
                        params sourcePath add(token)
                    }

                } else if (option startsWith("outpath")) {

                    params outPath = File new(arg substring(arg indexOf('=') + 1))
                    params clean = false

                } else if (option startsWith("outlib")) {

                    params outlib = arg substring(arg indexOf('=') + 1)

                } else if(option startsWith("backend")) {
                    params backend = arg substring(arg indexOf('=') + 1)

                    if(params backend != "c" && params backend != "json") {
                        "Unknown backend: %s." format(params backend) println()
                        params backend = "c"
                    }

                } else if (option startsWith("incpath")) {

                    params incPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith("I")) {

                    params incPath add(arg substring(2))

                } else if (option startsWith("libpath")) {

                    params libPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith("editor")) {

                    params editor = arg substring(arg indexOf('=') + 1)

                } else if (option startsWith("entrypoint")) {

                    params entryPoint = arg substring(arg indexOf('=') + 1)

                } else if (option == "c") {

                    params link = false

                } else if(option == "debugloop") {

                    params debugLoop = true

                } else if(option == "debuglibcache") {

                    params debugLibcache = true

                } else if(option startsWith("ignoredefine=")) {

                    params ignoredDefines add(option substring(13))

                } else if (option == "allerrors") {

                    BuildParams fatalError = false

                } else if(option startsWith("dist=")) {

                    params distLocation = File new(option substring(5))

                } else if(option startsWith("sdk=")) {

                    params sdkLocation = File new(option substring(4))

                } else if(option startsWith("libs=")) {

                    params libPath = File new(option substring(5))

                } else if(option startsWith("linker=")) {

                    params linker = option substring(7)

                } else if (option startsWith("L")) {

                    params libPath add(arg substring(2))

                } else if (option startsWith("l")) {

                    params dynamicLibs add(arg substring(2))

                } else if (option == "nolang") { // FIXME debug option.

                    params includeLang = false

                } else if (option == "nomain") {

                    params defaultMain = false

                } else if (option startsWith("gc=")) {

                    suboption := option substring(3)
                    if (suboption == "off") {
                        params enableGC = false
                        params undefineSymbol(BuildParams GC_DEFINE)
                    } else if (suboption == "dynamic") {
                        params enableGC = true
                        params dynGC = true
                        params defineSymbol(BuildParams GC_DEFINE)
                    } else if (suboption == "static") {
                        params enableGC = true
                        params dynGC = false
                        params defineSymbol(BuildParams GC_DEFINE)
                    } else {
                        ("Unrecognized option " + option + ". Valid values are gc=off, gc=dynamic, gc=static") println()
                    }

                } else if (option == "noclean") {

                    params clean = false

                } else if (option == "nohints") {

                    params helpful = false

                } else if (option == "nolibcache") {

                    params libcache = false

                } else if (option == "libcachepath") {

                    params libcachePath = option substring(option indexOf('=') + 1)

                } else if (option == "nolines") {

                    params lineDirectives = false

                } else if (option == "shout") {

                    params shout = true

                } else if (option == "q" || option == "quiet") {

                    // quiet mode
                    params shout = false
                    params verbose = false
                    params veryVerbose = false

                } else if (option == "timing" || option == "t") {

                    params timing = true

                } else if (option == "debug" || option == "g") {

                    params debug = true
                    params clean = false

                } else if (option == "verbose" || option == "v") {

                    params verbose = true

                } else if (option == "veryVerbose" || option == "vv") {

                    params verbose = true
                    params veryVerbose = true

                } else if (option == "stats") {

                    params stats = true

                } else if (option == "run" || option == "r") {

                    params run = true
                    params shout = false

                } else if (option startsWith("driver=")) {

                    driverName := option substring("driver=" length())
                    driver = match (driverName) {
                        case "combine" =>
                            CombineDriver new(params)
                        case "sequence" =>
                            SequenceDriver new(params)
                        case "make" =>
                            MakeDriver new(params)
                        case "dummy" =>
                            DummyDriver new(params)
                        case =>
                            "Unknown driver: %s" printfln(driverName)
                            null
                    }

                } else if (option startsWith("blowup=")) {

                    params blowup = option substring(7) toInt()

                } else if (option == "V" || option == "-version" || option == "version") {

                    printf("rock %s, built on %s at %s\n", Rock getVersionName(), ROCK_BUILD_DATE, ROCK_BUILD_TIME)
                    exit(0)

                } else if (option == "h" || option == "-help" || option == "help") {

                    Help printHelp()
                    exit(0)

                } else if (option startsWith("gcc")) {
                    if(option startsWith("gcc=")) {
                        params compiler = Gcc new(option substring(4))
                    } else {
                        params compiler = Gcc new()
                    }
                } else if (option startsWith("icc")) {
                    if(option startsWith("icc=")) {
                        params compiler = Icc new(option substring(4))
                    } else {
                        params compiler = Icc new()
                    }
                } else if (option startsWith("tcc")) {
                    if(option startsWith("tcc=")) {
                        params compiler = Tcc new(option substring(4))
                    } else {
                        params compiler = Tcc new()
                    }
                    params dynGC = true
                } else if (option startsWith("clang")) {
                    if(option startsWith("clang=")) {
                        params compiler = Clang new(option substring(6))
                    } else {
                        params compiler = Clang new()
                    }
                } else if (option == "onlyparse") {

                    driver = null
                    params onlyparse = true

                } else if (option == "onlycheck") {

                    driver = null

                } else if (option == "onlygen") {

                    driver = DummyDriver new(params)

                } else if (option startsWith("o=")) {

                    params binaryPath = arg substring(arg indexOf('=') + 1)

                } else if (option == "slave") {

                    params slave = true

                } else if (option startsWith("m")) {

                    arch := arg substring(2)
                    if (arch == "32" || arch == "64")
                        params arch = arg substring(2)
                    else
                        ("Unrecognized architecture: " + arch) println()

                } else {

                    printf("Unrecognized option: %s\n", arg)

                }
            } else if(arg startsWith("+")) {

                params compilerArgs add(arg substring(1))

            } else {
                lowerArg := arg toLower()
                if(lowerArg endsWith(".ooc")) {
                    modulePaths add(arg)
                } else {
                    if(lowerArg contains('.')) {
                        params additionals add(arg)
                    } else {
                        modulePaths add(arg+".ooc")
                    }
                }
            }
        }

        if(modulePaths isEmpty()) {
            printf("rock: no ooc files\n")
            exit(1)
        }

        if(params sourcePath isEmpty()) params sourcePath add(".")
        params sourcePath add(params sdkLocation path)

        errorCode := 0

        while(true) {
            for(modulePath in modulePaths) {
                code := parse(modulePath replace('/', File separator))
                if(code != 0) {
                    errorCode = 2 // C compiler failure.
                    break
                }
            }

            if(!params slave) break

            Terminal setFgColor(Color yellow). setAttr(Attr bright)
            "-- press [Enter] to re-compile --" println()
            Terminal reset()

            stdin readChar()
        }

        // c phase 5: clean up

        // oh that's a hack.
        if(params clean) {
            system("rm -rf %s" format(params outPath path))
        }

    }

    parse: func (moduleName: String) -> Int {

        first := static true

        moduleFile := params sourcePath getFile(moduleName)

        if(!moduleFile) {
            printf("File not found: %s\n", moduleName)
            exit(1)
        }

        modulePath := moduleFile path

        fullName := moduleName substring(0, moduleName length() - 4)
        module := Module new(fullName, params sourcePath getElement(moduleName) path, params , nullToken)
        module token = Token new(0, 0, module)
        module main = true
        module lastModified = moduleFile lastModified()

        // phase 1: parse
        AstBuilder new(modulePath, module, params)

        if(params onlyparse) {
            // Oookay, we're done here.
            success()
            return 0
        }

        if(params slave && !first) {
            // slave and non-first = cache is filled, we must re-parse every import.
            for(dep in module collectDeps()) {
                for(imp in dep getAllImports()) {
                    imp setModule(null)
                }
            }
            for(dep in module collectDeps()) {
                dep parseImports(null)
            }
        } else {
            // non-slave or first = cache is empty, everything will be parsed
            // anyway.
            module parseImports(null)
        }
        if(params verbose) printf("Finished parsing, now tinkering...\n")

        // phase 2: tinker
        if(!Tinkerer new(params) process(module collectDeps())) failure()

        // Clear the import's module cache so that they will be updated
        // with re-parsed modules (from the modified AstBuilder cache)
        // during the next collectDeps()
        if(params slave) for(candidate in module collectDeps()) for(imp in candidate getAllImports()) {
            imp setModule(null)
        }

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(params compiler != null && driver != null) {
                result := driver compile(module)
                if(result == 0) {
                    if(params shout) success()
                    if(params run) {
                        Process new(["./" + module simpleName] as ArrayList<String>) execute()
                    }
                } else {
                    if(params shout) failure()
                }
            }
        } else if(params backend == "json") {
            // json phase 3: generate.
            "FIXME! JSON generator disabled for now" println()

            //for(candidate in module collectDeps()) {
                //JSONGenerator new(params, candidate) write() .close()
            //}
        }

        first = false

        return 0

    }

    success: static func {
        Terminal setAttr(Attr bright)
        Terminal setFgColor(Color green)
        "[ OK ]" println()
        Terminal reset()
    }

    failure: static func {
        Terminal setAttr(Attr bright)
        Terminal setFgColor(Color red)
        "[FAIL]" println()
        Terminal reset()
        exit(1)
    }

}

system: extern func (command: String)
