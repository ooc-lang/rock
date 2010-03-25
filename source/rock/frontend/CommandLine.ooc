import io/File, os/Terminal
import structs/[ArrayList, List, Stack]
import text/StringTokenizer

import Help, Token, BuildParams, AstBuilder
import compilers/[Gcc, Clang, Icc, Tcc]
import drivers/[Driver, CombineDriver, SequenceDriver]
import ../backend/cnaughty/CGenerator
//import ../backend/json/JSONGenerator
import ../middle/[Module, Import]
import ../middle/tinker/Tinkerer

ROCK_BUILD_DATE, ROCK_BUILD_TIME: extern String

CommandLine: class {
    params: BuildParams
    driver: Driver
    
    init: func(args : ArrayList<String>) {
        params = BuildParams new()
        driver = CombineDriver new(params)
        
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
                    
                } else if (option == "c") {
                    
                    params link = false
        
                } else if(option == "debugloop") {

                    params debugLoop = true
                    
                } else if (option startsWith("L")) {
                    
                    params libPath add(arg substring(2))
                    
                } else if (option startsWith("l")) {
                    
                    params dynamicLibs add(arg substring(2))
                    
                } else if (option == "nolang") { // FIXME debug option.
                    
                    params includeLang = false
                    
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
                    
                } else if (option == "nolines") {
                    
                    params lineDirectives = false
                    
                } else if (option == "shout") {
                    
                    params shout = true
                    
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
                    
                } else if (option == "run" || option == "r") {
                    
                    params run = true
                    
                } else if (option startsWith("driver=")) {
                    
                    driverName := option substring("driver=" length())
                    if(driverName == "combine") {
                        driver = CombineDriver new(params) 
                    } else if (driverName == "sequence") {
                        driver = SequenceDriver new(params) 
                    } else {
                        ("Unknown driver: " + driverName) println()
                    }
                    
                } else if (option startsWith("blowup=")) {
                    
                    // TODO
                    params blowup = option substring(7) toInt()
                    
                } else if (option == "V" || option == "-version" || option == "version") {
                    
                    // TODO
                    printf("rock head, built on %s at %s\n", ROCK_BUILD_DATE, ROCK_BUILD_TIME)
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
                } else if (option == "onlygen") {
                    params compiler = null
                    params clean = false
                    
                } else if (option startsWith("o=")) {
                    
                    params binaryPath = arg substring(arg indexOf('=') + 1)
                
                } else if (option == "help-backends" || option == "-help-backends") {
                    
                    Help printHelpBackends()
                    exit(0)
                    
                } else if (option == "help-gcc" || option == "-help-gcc") {
                    
                    Help printHelpGcc()
                    exit(0)
                    
                } else if (option == "help-make" || option == "-help-make") {
                    
                    Help printHelpMake()
                    exit(0)
                    
                } else if (option == "help-none" || option == "-help-none") {
                    
                    Help printHelpNone()
                    exit(0)
                    
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
                
                driver compilerArgs add(arg substring(1))
                
            } else {
                lowerArg := arg toLower()
                if(lowerArg endsWith(".ooc")) {
                    modulePaths add(arg)
                } else {
                   if(lowerArg contains('.')) {
                        driver additionals add(arg)
                    } else {
                        modulePaths add(arg+".ooc")
                    }
                }
            }
        }
        
        if(modulePaths isEmpty()) {
            printf("rock: no files\n")
            exit(1)
        }
        
        if(params sourcePath isEmpty()) params sourcePath add(".")
        params sourcePath add(params sdkLocation path)
        
        errorCode := 0
        successCount := 0
        for(modulePath in modulePaths) {
            //try {
                code := parse(modulePath)
                if(code == 0) {
                    successCount += 1
                } else {
                    errorCode = 2 // C compiler failure.
                }
            //} catch(CompilationFailedError err) {
                //if(errorCode == 0) errorCode = 1 // ooc failure
                //System.err.println(err)
                //fail()
                //if(!params editor isEmpty()) {
                    //launchEditor(params editor, err)
                //}
            //}
            
            //if(params clean) params outPath deleteRecursive()
        }
        
    }
    
    parse: func (moduleName: String) -> Int {
        
        moduleFile := params sourcePath getFile(moduleName)
        
        if(!moduleFile) {
            printf("File not found: %s\n", moduleName)
            exit(1)
        }
        
        modulePath := moduleFile path
        
        fullName := moduleName substring(0, moduleName length() - 4)
        module := Module new(fullName, params sourcePath getElement(moduleName) path, nullToken)
        
        // phase 1: parse
        AstBuilder new(modulePath, module, params)
        
        // phase 2: tinker
        moduleList := ArrayList<Module> new()
        collectModules(module, moduleList)
        if(!Tinkerer new(params) process(moduleList)) failure()
        
        if(params backend == "c") {
            // c phase 3: generate.
            params outPath mkdirs()
            for(candidate in moduleList) {
                CGenerator new(params, candidate) write() .close()
            }
            // c phase 4: launch the C compiler
            if(params compiler) {
                result := driver compile(module)
                if(result == 0) {
                    success()
                } else {
                    failure()
                }
                // c phase 5: clean up

                // oh that's a hack.
                if(params clean) {
                    system("rm -rf %s" format(params outPath path))
                }
            }
        } else if(params backend == "json") {
            // json phase 3: generate.
            for(candidate in moduleList) {
                "FIXME! JSON generator disabled for now" println()
                //JSONGenerator new(params, candidate) write() .close()
            }
        }
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
    
    collectModules: func (module: Module, list: List<Module>) {
        
        list add(module)
		for(imp in module getAllImports()) {
			if(!list contains(imp getModule())) {
				collectModules(imp getModule(), list)
			}
		}
        
    }
    
}

system: extern func (command: String)
