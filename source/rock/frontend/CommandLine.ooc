import io/File
import structs/[Array, ArrayList, List]
import text/StringTokenizer

import BuildParams
import compilers/[Gcc, Clang, Icc, Tcc]
import Help

CommandLine: class {
	params: BuildParams
	//driver: CombineDriver
	
	init: func(args : List<String>) {
		params = BuildParams new()
		//driver = CombineDriver new(params 
		
		modulePaths := ArrayList<String> new()
		nasms := ArrayList<String> new()
		params compiler = Gcc new()
		
		for (arg: String in args) {
			if (arg startsWith("-")) {
				option := arg substring(1)
				
				if (option startsWith("sourcepath")) {
        			
        			sourcePathoption := arg substring(arg indexOf('=') + 1)
        			tokenizer := StringTokenizer new(sourcePathoption , File separator)
					for (token: String in tokenizer) {
						params sourcePath add(token)
					}
        			
        		} else if (option startsWith("outpath")) {
        			
        			params outPath = File new(arg substring(arg indexOf('=') + 1))
        			params clean = false
        			
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
        			
        		} else if (option startsWith("L")) {
        			
        			params libPath add(arg substring(2))
        			
        		} else if (option startsWith("l")) {
        			
        			params dynamicLibs add(arg substring(2))
        			
        		} else if (option == "dyngc") {
        			
        			"Deprecated option -dyngc, you should use -gc=dynamic instead." println()
        			params dynGC = true
        			
        		} else if (option == "nogc") {
        			
        			"Deprecated option -nogc, you should use -gc=off instead." println()
        			params enableGC = false
        			
        		} else if (option startsWith("gc=")) {
        			
        			suboption := option substring(3)
        			if (suboption == "off") {
        				params enableGC = false
        			} else if (suboption == "dynamic") {
        				params enableGC = true
        				params dynGC = true
        			} else if (suboption == "static") {
        				params enableGC = true
        				params dynGC = false
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
        			
        			params veryVerbose = true
        			
        		} else if (option == "run" || option == "r") {
        			
        			params run = true
        			
        		} else if (option startsWith("driver=")) {
        			
        			driverName := option .substring("driver=" length())
        			if(driverName == "combine") {
						// TODO
						"FIXME! CombineDriver" println()
        				//driver = CombineDriver(params) 
        			} else if (driverName == "sequence") {
						// TODO
						"FIXME! SequenceDriver" println()
        				//driver = SequenceDriver new(params) 
        			} else {
        				("Unknown driver: " + driverName) println()
        			}
        			
        		} else if (option startsWith("blowup=")) {
        			
					// TODO
					"FIXME! blowup" println()
        			// params blowup = Integer.parseInt(option .substring("blowup=".length()))
        			
        		} else if (option == "V" || option == "-version" || option == "version") {
        			
					// TODO
        			"FIXME! Version info!" println()
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
			}
		}
	}
}

main: func(args: Array<String>) {
	CommandLine new(args)
}