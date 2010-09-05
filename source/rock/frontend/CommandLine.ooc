import io/File, os/[Terminal, Process, Pipe]
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

import rock/RockVersion
import Help, Token, BuildParams, AstBuilder
import compilers/[Gcc, Clang, Icc, Tcc]
import drivers/[Driver, CombineDriver, SequenceDriver, MakeDriver, DummyDriver]
import ../backend/json/JSONGenerator
import ../backend/explain/ExplanationGenerator
import ../middle/[Module, Import]
import ../middle/tinker/Tinkerer

ROCK_BUILD_DATE, ROCK_BUILD_TIME: extern CString
system: extern func (command: CString)


CommandLine: class {
    params: BuildParams
    driver: Driver

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

            if (arg startsWith?("-")) {
                option := arg substring(1)

                if (option startsWith?("sourcepath=")) {

                    sourcePathOption := arg substring(arg indexOf('=') + 1)
                    tokenizer := StringTokenizer new(sourcePathOption, File pathDelimiter)
                    for (token: String in tokenizer) {
                        params sourcePath add(token)
                    }

                } else if (option startsWith?("outpath=")) {

                    params outPath = File new(arg substring(arg indexOf('=') + 1))
                    params clean = false

                } else if (option startsWith?("outlib")) {

                    "Deprecated option %s! Use -staticlib instead. Abandoning.\n" printf(option toCString())
                    exit(1)

                } else if (option startsWith?("staticlib")) {

                    idx := arg indexOf('=')
                    if(idx == -1) {
                        params staticlib = ""
                    } else {
                        params staticlib = arg substring(idx + 1)
                    }
                    params libcache = false

                } else if (option startsWith?("dynamiclib")) {

                    idx := arg indexOf('=')
                    if(idx == -1) {
                        params dynamiclib = ""
                    } else {
                        params dynamiclib = arg substring(idx + 1)
                    }

                } else if (option startsWith?("libfolder=")) {

                    idx := arg indexOf('=')
                    params libfolder = arg substring(idx + 1)

                } else if(option startsWith?("backend")) {
                    params backend = arg substring(arg indexOf('=') + 1)

                    if(params backend != "c" && params backend != "json" && params backend != "explain") {
                        "Unknown backend: %s." format(params backend toCString()) println()
                        params backend = "c"
                    }

                } else if (option startsWith?("incpath=")) {

                    params incPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith?("D")) {

                    params defineSymbol(arg substring(2))

                } else if (option startsWith?("I")) {

                    params incPath add(arg substring(2))

                } else if (option startsWith?("libpath")) {

                    params libPath add(arg substring(arg indexOf('=') + 1))

                } else if (option startsWith?("editor")) {

                    params editor = arg substring(arg indexOf('=') + 1)

                } else if (option startsWith?("entrypoint")) {

                    params entryPoint = arg substring(arg indexOf('=') + 1)

                } else if (option == "dce") {

                    params dce = true

                } else if (option == "newsdk") {

                    params newsdk = true

                } else if (option == "newstr") {

                    params newstr = true

                } else if(option == "cstrings") {

                    params newstr = false

                } else if (option == "inline") {

                    params inlining = true

                } else if (option == "no-inline") {

                    params inlining = false

                } else if (option == "c") {

                    params link = false

                } else if(option == "debugloop") {

                    params debugLoop = true

                } else if(option == "debuglibcache") {

                    params debugLibcache = true

                } else if(option startsWith?("ignoredefine=")) {

                    params ignoredDefines add(option substring(13))

                } else if (option == "allerrors") {

                    params fatalError = false

                } else if(option startsWith?("dist=")) {

                    params distLocation = File new(option substring(5))

                } else if(option startsWith?("sdk=")) {

                    params sdkLocation = File new(option substring(4))

                } else if(option startsWith?("libs=")) {

                    params libPath = File new(option substring(5))

                } else if(option startsWith?("linker=")) {

                    params linker = option substring(7)

                } else if (option startsWith?("L")) {

                    params libPath add(arg substring(2))

                } else if (option startsWith?("l")) {

                    params dynamicLibs add(arg substring(2))

                } else if (option == "nolang") { // FIXME debug option.

                    params includeLang = false

                } else if (option == "nomain") {

                    params defaultMain = false

                } else if (option startsWith?("gc=")) {

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

                } else if (option startsWith?("driver=")) {

                    driverName := option substring("driver=" length())
                    driver = match (driverName) {
                        case "combine" =>
                            params libcache = false
                            CombineDriver new(params)
                        case "sequence" =>
                            SequenceDriver new(params)
                        case "make" =>
                            MakeDriver new(params)
                        case "dummy" =>
                            DummyDriver new(params)
                        case =>
                            "Unknown driver: %s\n" printf(driverName toCString())
                            null
                    }

                } else if (option startsWith?("blowup=")) {

                    params blowup = option substring(7) toInt()

                } else if (option == "V" || option == "-version" || option == "version") {

                    printf("rock %s, built on %s at %s\n", RockVersion getName() toCString(), ROCK_BUILD_DATE, ROCK_BUILD_TIME)
                    exit(0)

                } else if (option == "h" || option == "-help" || option == "help") {

                    Help printHelp()
                    exit(0)

                } else if (option startsWith?("gcc")) {
                    if(option startsWith?("gcc=")) {
                        params compiler = Gcc new(option substring(4))
                    } else {
                        params compiler = Gcc new()
                    }
                } else if (option startsWith?("icc")) {
                    if(option startsWith?("icc=")) {
                        params compiler = Icc new(option substring(4))
                    } else {
                        params compiler = Icc new()
                    }
                } else if (option startsWith?("tcc")) {
                    if(option startsWith?("tcc=")) {
                        params compiler = Tcc new(option substring(4))
                    } else {
                        params compiler = Tcc new()
                    }
                    params dynGC = true
                } else if (option startsWith?("clang")) {
                    if(option startsWith?("clang=")) {
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

                } else if (option startsWith?("o=")) {

                    params binaryPath = arg substring(arg indexOf('=') + 1)

                } else if (option == "slave") {

                    params slave = true

                } else if (option startsWith?("m")) {

                    arch := arg substring(2)
                    if (arch == "32" || arch == "64")
                        params arch = arg substring(2)
                    else
                        ("Unrecognized architecture: " + arch) println()

                } else {

                    printf("Unrecognized option: %s\n", arg toCString())

                }
            } else if(arg startsWith?("+")) {

                params compilerArgs add(arg substring(1))

            } else {
                lowerArg := arg toLower()
                if(lowerArg endsWith?(".ooc")) {
                    modulePaths add(arg)
                } else {
                    if(lowerArg contains?('.')) {
                        params additionals add(arg)
                    } else {
                        modulePaths add(arg+".ooc")
                    }
                }
            }
        }

        if(modulePaths empty?() && !params libfolder) {
            "rock: no ooc files" println()
            exit(1)
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

            if(params verbose) "Building lib for folder %s to name %s\n" printf(params libfolder toCString(), name toCString())

            dummyModule = Module new("__lib__/%s.ooc" format(name toCString()), ".", params, nullToken)
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

        if(params staticlib != null || params dynamiclib != null) {
            if(modulePaths getSize() != 1 && !params libfolder) {
                "Error: you can use -staticlib of -dynamiclib only when specifying a unique .ooc file, not %d of them.\n" printf(modulePaths getSize())
                exit(1)
            }
            moduleName := File new(dummyModule ? dummyModule path : modulePaths[0]) name()
            moduleName = moduleName[0..moduleName length() - 4]
            basePath := File new("build", moduleName) getPath()
            if(params staticlib == "") {
                params clean = false
                params defaultMain = false
                params outPath = File new(basePath, "include")
                staticExt := ".a"
                params staticlib = File new(File new(basePath, "lib"), moduleName + staticExt) getPath()
            }
            if(params dynamiclib == "") {
                params clean = false
                params defaultMain = false
                params outPath = File new(basePath, "include")
                prefix := "lib"
                dynamicExt := ".so"
                // TODO: version blocks for this is evil. What if we want to cross-compile?
                // besides, it's missing some platforms.
                version(windows) {
                    dynamicExt = ".dll"
                    prefix = ""
                }
                version(apple) {
                    dynamicExt = ".dylib"
                }
                params dynamiclib = File new(File new(basePath, "lib"), prefix + moduleName + dynamicExt) getPath()

                // TODO: this is too gcc/Linux-specific: there should be a good way
                // to abstract that away
                params compilerArgs add("-fpic")
                params compilerArgs add("-shared")
                params compilerArgs add("-Wl,-soname," + params dynamiclib)
                params binaryPath = params dynamiclib
                //driver = CombineDriver new(params)
                params libcache = false // libcache is incompatible with combine driver
                File new(basePath, "lib") mkdirs()
            }
        }

        if(params sourcePath empty?()) {
            params sourcePath add(".")
        }
        params sourcePath add(params sdkLocation path)

        errorCode := 0

        while(true) {
            try {
                if(dummyModule) {
                    postParsing(dummyModule)
                } else {
                    for(modulePath in modulePaths) {
                        code := parse(modulePath replaceAll('/', File separator))
                        if(code != 0) {
                            errorCode = 2 // C compiler failure.
                            break
                        }
                    }
                }
            } catch e: CompilationFailedException {
                if(!params slave) e rethrow()
            }

            if(!params slave) break
            //params veryVerbose = true

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

    clean: func {
        // oh that's a hack.
        system("rm -rf %s" format(params outPath path toCString()) toCString())
    }

    cleanHardcore: func {
        clean()
        // oh that's the same hack. Someone implement File recursiveDelete() already.
        system("rm -rf %s" format(params libcachePath toCString()) toCString())
    }

    parse: func (moduleName: String) -> Int {
        (moduleFile, pathElement) := params sourcePath getFile(moduleName)
        if(!moduleFile) {
            printf("File not found: %s\n", moduleName toCString())
            exit(1)
        }

        modulePath := moduleFile path
        fullName := moduleName[0..-4]
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
        if(params verbose) printf("\rFinished parsing, now tinkering...                                                   \n")

        // phase 2: tinker
        if(!Tinkerer new(params) process(module collectDeps())) failure(params)

        if(params backend == "c") {
            // c phase 3: launch the driver
            if(params compiler != null && driver != null) {
                result := driver compile(module)
                if(result == 0) {
                    if(params shout) success()
                    if(params run) {
                        foo := ArrayList<String> new()
                        foo add("./" + module simpleName)
                        Process new(foo) execute()
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
        } else if(params backend == "explain") {
            params clean = false
            for(candidate in module collectDeps()) {
                ExplanationGenerator new(params, candidate) write() .close()
            }
            Terminal setAttr(Attr bright)
            Terminal setFgColor(Color blue)
            "[ Produced documentation in rock_tmp/ ]" println()

            Terminal setFgColor(Color red)

            old := File new(params outPath getPath() + File separator + module getSourceFolderName(), module getPath(".markdown"))

            out: String

            markdown := Process new(["markdown", old getPath()])
            markdown setStdout(Pipe new()) .executeNoWait()
            markdown communicate(null, out&, null)

            new := File new(module simpleName+".html")
            new write("<html>
            <head>
                <script type=\"text/javascript\" charset=\"utf-8\" src=\"http://code.jquery.com/jquery-1.4.2.min.js\"></script>
                <link href='http://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light' rel='stylesheet' type='text/css'>
                <link href='http://fonts.googleapis.com/css?family=Molengo' rel='stylesheet' type='text/css'>
                <link href='http://fonts.googleapis.com/css?family=IM+Fell+DW+Pica' rel='stylesheet' type='text/css'>
                <title>ooc Explanations: doc_test</title>
            </head>
                <body onload=\"bootstrap()\">
                <script type=\"text/javascript\" charset=\"utf-8\">
                function bootstrap() {
                    $('body').attr('style',\"padding: 0;margin:  0;border:  0;background: #EEEEFF;\");
                    $('h1').attr('style',\"font-family: 'IM Fell DW Pica', arial, serif;padding-left: 1em;background: black;color: yellow;font-size: 2em;\");
                    $('h2').attr('style',\"font-family:'Josefin Sans Std Light',arial,serif;background:black;color:white;padding-top:5px;padding-left: 1em;border-top-left-radius: 50px;\");
                    $('p').attr('style',\"font-family: 'Molengo', arial, serif;\");
                    $('li').attr('style',\"font-family: 'Molengo', arial, serif;\");
                    $('h1').before('<div id=\"file_head\">');
                    $('body').children().each(function (i) { if (this.tagName == \"H2\") { return false } else if (this.tagName != \"DIV\") { $('#file_head').append(this)}});
                    $('#file_head').append('<div id=\"text\">');
                    $('#file_head').children().each(function (i) { if (this.tagName != \"DIV\" && this.tagName != \"H1\") { $('#text').append(this) }});
                    $(\"h2\").each(function() { var $h2 = $(this);$(\"<div class='text'/>\").append($h2.nextUntil(\"h2\")).insertAfter($h2).add($h2).wrapAll(\"<div class='box'/>\");});
                    $('.box').attr('style','width: 80%;margin: auto;border-top-left-radius: 25px;border-bottom-right-radius: 50px;background: rgba(56%, 91%, 100%, 0.5);')
                    $('.text').attr('style','padding: 0 1em 1em 1em;')
                    $('#text').attr('style','width: 70%;margin: auto;padding: 0.1em;');
                }
            </script>\n" + out + "\n</body></html>")

            Terminal setFgColor(Color yellow)
            ("Attempted to generate "+new getPath()+" [ markdown script needs to be in $PATH ]") println()
            Terminal reset()
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

