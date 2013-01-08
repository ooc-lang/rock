import io/File, os/[Terminal, Process, Pipe]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

import rock/RockVersion
import Help, Token, BuildParams, AstBuilder, PathList
import compilers/[Gcc, Clang, Icc, Tcc]
import drivers/[Driver, SequenceDriver, MakeDriver, DummyDriver]
import ../backend/json/JSONGenerator
import ../middle/[Module, Import, UseDef]
import ../middle/tinker/Tinkerer

system: extern func (command: CString)

CommandLine: class {
    params: BuildParams
    driver: Driver
    cCPath := ""

    setCompilerPath: func {
        if (params compiler != null && cCPath != "") params compiler setExecutable(cCPath)
    }

    warnUseLong: func (option: String) {
        "[WARNING] Option -%s is deprecated, use --%s instead." printfln(option, option)
    }

    init: func(args : ArrayList<String>) {

        params = BuildParams new(args[0])
        driver = SequenceDriver new(params)

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
                    params clean = false

                } else if (option startsWith?("staticlib")) {

                    "[ERROR] staticlib parameter is deprecated" println()
                    failure(params)

                } else if (option startsWith?("dynamiclib")) {

                    "[ERROR] dynamiclib parameter is deprecated" println()
                    failure(params)

                } else if (option startsWith?("packagefilter=")) {

                    "[ERROR] packagefilter parameter is deprecated" println()
                    failure(params)

                } else if (option startsWith?("libfolder=")) {

                    "[ERROR] libfolder parameter is deprecated" println()
                    failure(params)

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

                    if(!longOption) warnUseLong("newsdk")
                    params newsdk = true

                } else if (option == "newstr") {

                    if(!longOption) warnUseLong("newstr")
                    params newstr = true

                } else if(option == "cstrings") {

                    if(!longOption) warnUseLong("cstrings")
                    params newstr = false

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

                    if(!longOption) warnUseLong("nolibcache")
                    params libcache = false

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
                            "[WARNING] Unknown driver: %s" printfln(driverName)
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
                    cCPath = option substring(3)
                    setCompilerPath()

                } else if (option startsWith?("gcc")) {

                    if(!longOption) warnUseLong("gcc")
                    params compiler = Gcc new()
                    setCompilerPath()

                } else if (option startsWith?("icc")) {

                    if(!longOption) warnUseLong("icc")
                    params compiler = Icc new()
                    setCompilerPath()

                } else if (option startsWith?("tcc")) {

                    if(!longOption) warnUseLong("tcc")
                    params compiler = Tcc new()
                    params dynGC = true
                    setCompilerPath()

                } else if (option startsWith?("clang")) {

                    if(!longOption) warnUseLong("clang")
                    params compiler = Clang new()
                    setCompilerPath()

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

                    params slave = true

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
                        // used for example if you want to pass .s assembly files to gcc
                        params additionals add(arg)
                    case =>
                        // probably an ooc file without the extension
                        modulePaths add(arg+".ooc")
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

        dummyModule: Module

        if(params libfolder) {
            if(params staticlib == null && params dynamiclib == null) {
                // by default, build both
                params staticlib = ""
                params dynamiclib = ""
            }

            idx := params libfolder indexOf(File pathDelimiter)
            libfolder := File new(match idx {
                case -1 => params libfolder
                case    => params libfolder substring(0, idx)
            })

            name := (idx == -1 ? libfolder getAbsoluteFile() name() : params libfolder substring(idx + 1))
            params libfolder = libfolder getPath()
            params sourcePath add(params libfolder)

            if(params verbose) "Building lib for folder %s to name %s" printfln(params libfolder, name)

            dummyModule = Module new("__lib__/%s.ooc" format(name), ".", params, nullToken)
            dummyModule dummy = true
            libfolder walk(|f|
                // sort out links to non-existent destinations.
                if(!f exists?())
                    return true // = continue

                path := f getPath()
                if (!path endsWith?(".ooc")) return true

                fullName := f getAbsolutePath()
                fullName = fullName substring(libfolder getAbsolutePath() length() + 1, fullName length() - 4)

                dummyModule addImport(Import new(fullName, nullToken))
                true
            )
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

        while(true) {
            try {
                if(dummyModule) {
                    postParsing(dummyModule)
                } else for(modulePath in modulePaths) {
                    code := parse(modulePath replaceAll('/', File separator))
                    if(code != 0) {
                        errorCode = 2 // C compiler failure.
                        break
                    }
                }
            } catch e: CompilationFailedException {
                if(!params slave) e rethrow()
            }

            if(!params slave) break

            Terminal setFgColor(Color yellow). setAttr(Attr bright)
            "-- press [Enter] to re-compile, [c] to clean, [q] to quit. --" println()
            Terminal reset()

            line := stdin readLine()
            if(line == "c") {
                Terminal setFgColor(Color yellow). setAttr(Attr bright)
                "-- Pressed 'c', cleaning... and recompiling everything! --" println()
                Terminal reset()
                cleanHardcore()
            }
            if(line == "q") {
                Terminal setFgColor(Color yellow). setAttr(Attr bright)
                "-- Pressed 'q', exiting... seeya! --" println()
                Terminal reset()
                exit(0)
            }
        }

        // c phase 5: clean up
        if(params clean) {
            clean()
        }

    }

    prepareCompilationFromUse: func (uzeFile: File, modulePaths: ArrayList<String>) {
        // extract '.use' from use file
        identifier := uzeFile name()[0..-5]
        uze := UseDef new(identifier)
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

        if(params slave && !first) {
            // slave and non-first = cache is filled, we must re-check every import.
            deadModules := ArrayList<Module> new()
            AstBuilder cache each(|mod|
                if(File new(mod oocPath) lastModified() > mod lastModified) {
                    deadModules add(mod)
                }
                mod getAllImports() each(|imp|
                    imp setModule(null)
                )
            )
            deadModules each(|mod|
                mod dead = true
                AstBuilder cache remove(File new(mod oocPath) getAbsolutePath())
            )
        }
        module parseImports(null)
        if(params verbose) {
            "\rFinished parsing, now tinkering...                                                   " println()
        }

        // phase 2: tinker
        if(!Tinkerer new(params) process(module collectDeps())) {
            failure(params)
        }

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(params compiler != null && driver != null) {
                if(!params verbose) params compiler silence = true
                result := driver compile(module)
                if(result == 0) {
                    if(params shout) success()
                    if(params run) {
                        Process new(["./" + module simpleName]) execute()
                    }
                } else {
                    if(params shout) failure(params)
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

        // in slave-mode, we raise a specific exception so we have a chance to loop
        if(params slave) {
            CompilationFailedException new() throw()
        }
        exit(1)
    }

}

CompilationFailedException: class extends Exception {
    init: func {
        super("Compilation failed!")
    }
}

