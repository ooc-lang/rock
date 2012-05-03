import io/File, os/[Terminal, Process, Pipe]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

import rock/RockVersion
import Help, Token, BuildParams, AstBuilder, PathList
import compilers/[Gcc, Clang, Icc, Tcc]
import drivers/[Driver, MakeDriver]
import ../middle/[Module, Import, UseDef]
import ../middle/tinker/Tinkerer

ROCK_BUILD_DATE, ROCK_BUILD_TIME: extern CString
system: extern func (command: CString)


CommandLine: class {
    params: BuildParams
    driver: Driver
    cCPath := ""

    setCompilerPath: func {
        if (params compiler != null && cCPath != "") params compiler setExecutable(cCPath)
    }

    warnUseLong: func (option: String) {
        "[WARNING] Option -%s is deprecated, use --%s instead. It will completely disappear in later releases." printfln(option, option)
    }

    init: func(args : ArrayList<String>) {

        params = BuildParams new(args[0])
        driver = MakeDriver new(params)

        modulePaths := ArrayList<String> new()
        params compiler = Gcc new()

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
                    tokenizer := StringTokenizer new(sourcePathOption, File pathDelimiter)
                    for (token: String in tokenizer) {
						// rock allows '/' instead of '\' on Win32
                        params sourcePath add(token replaceAll('/', File separator))
                    }

                } else if (option startsWith?("outpath=")) {

                    if(!longOption) warnUseLong("outpath")
                    params outPath = File new(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith?("packagefilter=")) {

                    if(!longOption) warnUseLong("packagefilter")
                    idx := arg indexOf('=')
                    params packageFilter = arg substring(idx + 1)

                } else if (option startsWith?("libfolder=")) {

                    if(!longOption) warnUseLong("libfolder")
                    idx := arg indexOf('=')
                    params libfolder = arg substring(idx + 1)

                } else if(option startsWith?("backend")) {

                    if(!longOption) warnUseLong("backend")
                    params backend = arg substring(arg indexOf('=') + 1)

                    if(params backend != "c") {
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

                } else if (option startsWith?("entrypoint")) {

                    if(!longOption) warnUseLong("entrypoint")
                    params entryPoint = arg substring(arg indexOf('=') + 1)

                } else if (option == "allerrors") {

                    if(!longOption) warnUseLong("allerrors")
                    params fatalError = false

                } else if(option startsWith?("dist=")) {

                    if(!longOption) warnUseLong("dist")
                    params distLocation = File new(option substring(5))

                } else if(option startsWith?("sdk=")) {

                    if(!longOption) warnUseLong("sdk")
                    params sdkLocation = File new(option substring(4))

                } else if(option startsWith?("libs=")) {

                    if(!longOption) warnUseLong("libs")
                    params libPath = File new(option substring(5))

                } else if (option startsWith?("L")) {

                    params libPath add(option substring(1))

                } else if (option startsWith?("l")) {

                    params dynamicLibs add(option substring(1))

                } else if (option == "nomain") {

                    if(!longOption) warnUseLong("nomain")
                    params defaultMain = false

                } else if (option == "nohints") {

                    if(!longOption) warnUseLong("nohints")
                    params helpful = false

                } else if (option == "nolines") {

                    if(!longOption) warnUseLong("inline")
                    params lineDirectives = false
                    
                } else if (option == "q" || option == "quiet") {

                    // quiet mode
                    if(!longOption && option != "q") warnUseLong("quiet")
                    params verbose = false
                    params veryVerbose = false

                } else if (option == "debug" || option == "g") {

                    if(!longOption && option != "g") warnUseLong("debug")
                    params debug = true

                } else if (option == "verbose" || option == "v") {

                    if(!longOption && option != "v") warnUseLong("verbose")
                    params verbose = true

                } else if (option == "veryVerbose" || option == "vv") {

                    if(!longOption && option != "vv") warnUseLong("veryVerbose")
                    params verbose = true
                    params veryVerbose = true
                    params sourcePath debug = true

                } else if (option startsWith?("driver=")) {

                    driverName := option substring("driver=" length())
                    driver = match (driverName) {
                        case "make" =>
                            MakeDriver new(params)
                        case =>
                            "Unknown driver: %s" printfln(driverName)
                            null
                    }

                } else if (option startsWith?("blowup=")) {

                    if(!longOption) warnUseLong("blowup")
                    params blowup = option substring(7) toInt()

                } else if (option == "V" || option == "version") {

                    if(!longOption && option != "V") warnUseLong("version")
                    "rock %s, built on %s at %s" printfln(RockVersion getName(), ROCK_BUILD_DATE, ROCK_BUILD_TIME)
                    exit(0)

                } else if (option == "h" || option == "help") {

                    if(!longOption && option != "h") warnUseLong("help")
                    Help printHelp()
                    exit(0)

                } else if (option == "onlyparse") {

                    if(!longOption) warnUseLong("onlyparse")
                    driver = null
                    params onlyparse = true

                } else if (option == "onlycheck") {

                    if(!longOption) warnUseLong("onlycheck")
                    driver = null

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
                        // used for example if you want to pass .s assembly files to gcc
                        params additionals add(arg)
                    case =>
                        // probably an ooc file without the extension
                        modulePaths add(arg+".ooc")
                }
            }
        }

        if(modulePaths empty?() && !params libfolder) {
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
        }
        params sourcePath add(params sdkLocation path)

        for (modulePath in modulePaths) {
            code := parse(modulePath replaceAll('/', File separator))
            if (code != 0) {
                failure()
            }
        }
    }

    prepareCompilationFromUse: func (uzeFile: File, modulePaths: ArrayList<String>) {
        uze := UseDef new(uzeFile name())
        uze read(uzeFile, params)
        if(uze main) {
            // compile as a program
            uze apply(params)
            modulePaths add(uze main)
        } else {
            // compile as a library
            params libfolder = uze sourcePath ? uze sourcePath : "."
        }
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
            return 0
        }

        module parseImports(null)
        if(params verbose) "\rFinished parsing, now tinkering...                                                   " println()

        // phase 2: tinker
        if(!Tinkerer new(params) process(module collectDeps())) {
            failure()
        }

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(driver != null) {
                if(!params verbose) params compiler silence = true

                result := driver compile(module)
                if(result == 0) {
                    success()
                } else {
                   failure()
                }
            }
        }

        first = false
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

CompilationFailedException: class extends Exception {
    init: func {
        super("Compilation failed!")
    }
}
