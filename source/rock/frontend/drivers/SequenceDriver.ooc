import io/[File], os/Process, text/Buffer
import structs/[List, ArrayList, HashMap]
import ../[BuildParams, Target]
import ../compilers/AbstractCompiler
import ../../middle/[Module, UseDef]
import Driver, Archive

SourceFolder: class {
    name: String
    params: BuildParams
    outlib: String
    
    modules := ArrayList<Module> new()
    archive : Archive
    
    init: func (=name, =params) {
        outlib = "%s%c%s-%s.a" format(params libcachePath, File separator, name, Target toString())
        archive = Archive new(outlib)
    }
}

SequenceDriver: class extends Driver {

    init: func (.params) { super(params) }

	compile: func (module: Module) -> Int {
		
		copyLocalHeaders(module, params, ArrayList<Module> new())
		
		if(params verbose) {
			("Sequence driver, using " + params sequenceThreads + " thread(s).") println()
		}
		
		toCompile := collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<String> new())
        
        oPaths := ArrayList<String> new()
		
        for(sourceFolder in toCompile) {
            if(params verbose) printf("Building %s/\n", sourceFolder name)
            code := buildSourceFolder(sourceFolder, oPaths)
            if(code != 0) return code
        }
        
        if(params libcache) {
            path := "%s%c%s.a" format(params libcachePath, File separator, module getUnderName())
            Archive saveAll(oPaths, path)
            oPaths clear()
            oPaths add(path)
        }
		
		if(params link) {
			
			initCompiler(params compiler)
            
			if(params linker != null) params compiler setExecutable(params linker)    
			
			for(oPath in oPaths) {
				params compiler addObjectFile(oPath)    
			}
			
            for(define in params defines) {
                params compiler defineSymbol(define)
            }
            for(dynamicLib in params dynamicLibs) {
                params compiler addDynamicLibrary(dynamicLib)
            }
            for(incPath in params incPath getPaths()) {
                params compiler addIncludePath(incPath getPath())
            }
            for(additional in params additionals) {
                params compiler addObjectFile(additional)
            }
			for(libPath in params libPath getPaths()) {
				params compiler addLibraryPath(libPath getAbsolutePath())    
			}

			if(params binaryPath != "") {
                params compiler setOutputPath(params binaryPath)
            } else {
                params compiler setOutputPath(module simpleName)
            }
            
            libs := getFlagsFromUse(module)
            for(lib in libs) {
                params compiler addObjectFile(lib)
            }
			
			if(params enableGC) {
                params compiler addDynamicLibrary("pthread")
                if(params dynGC) {
                    params compiler addDynamicLibrary("gc")
                } else {
                    arch := params arch equals("") ? Target getArch() : params arch
                    libPath := "libs/" + Target toString(arch) + "/libgc.a"
                    params compiler addObjectFile(File new(params distLocation, libPath) path)
                }
            }
			if(params verbose) params compiler getCommandLine() println()
	
			code := params compiler launch()    
			
			if(code != 0) {
                fprintf(stderr, "C compiler failed, aborting compilation process\n")
				return code
			}
		
		}
		
		if(params outlib != null) {
			toCompile := collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<String> new())
            modules := ArrayList<Module> new()
            
			for(sourceFolder in toCompile) {
                modules addAll(sourceFolder modules)
			}
            
            if(params verbose) "Building archive %s with all object files." format(params outlib) println()
            
            archive := Archive new(params outlib)
            for(module in modules) {
                archive add(module)
            }
            archive save(params)
		}
		
		
		return 0    
		
	}
    
    /**
       Build a source folder into object files or a static library
     */
    buildSourceFolder: func (sourceFolder: SourceFolder, objectFiles: List<String>) -> Int {
        
        archive := sourceFolder archive
        
        // if lib-caching, we compile every object file to a .a static lib
        if(params libcache) {
            objectFiles add(sourceFolder outlib)
            
            if(archive exists?) {
                for(module in sourceFolder modules) {
                    if(!archive upToDate?(module)) {
                        code := buildIndividual(module, sourceFolder, null, archive, true)
                        if(code != 0) return code
                    }
                }
                
                archive save(params)
                return 0
            }
        }
        
        oPaths := ArrayList<String> new()
        for(module in sourceFolder modules) {
            code := buildIndividual(module, sourceFolder, oPaths, archive, false)
            if(code != 0) return code
        }
        
        if(params libcache) {
            // now build a static library
            if(params veryVerbose) printf("Saving to library %s\n", sourceFolder outlib)
            archive save(params)
        } else {
            if(params veryVerbose) printf("Lib caching disabled, building from .o files\n")
            objectFiles addAll(oPaths)
        }
        
        return 0
        
    }
    
    /**
       Build an individual ooc files to its .o file, add it to oPaths
     */
    buildIndividual: func (module: Module, sourceFolder: SourceFolder, oPaths: List<String>, archive: Archive, force: Bool) -> Int {
        
        initCompiler(params compiler)
        params compiler setCompileOnly()
        
        path := File new(params outPath, module getPath("")) getPath()
        oPath := path + ".o"    
        cPath := path + ".c"    
        if(oPaths) {
            oPaths add(oPath)
        }
        
        cFile := File new(cPath)
        oFile := File new(oPath)
        
        comparison := (archive ? File new(archive outlib) lastModified() : oFile lastModified())
        
        if(force || cFile lastModified() > comparison) {
            
            if(params veryVerbose) printf("%s not in cache or out of date, recompiling\n", module getFullName())
            
            params compiler addObjectFile(cPath)    
            params compiler setOutputPath(oPath)    
            
            params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())
            params compiler addIncludePath(params outPath getPath())
                    
            for(define in params defines) {
                params compiler defineSymbol(define)
            }
            for(dynamicLib in params dynamicLibs) {
                params compiler addDynamicLibrary(dynamicLib)
            }
            for(incPath in params incPath getPaths()) {
                params compiler addIncludePath(incPath getPath())
            }
            for(compilerArg in params compilerArgs) {
                params compiler addObjectFile(compilerArg)
            }

            libs := getFlagsFromUse(sourceFolder)
            for(lib in libs) {
                params compiler addObjectFile(lib)
            }
            
            if(params verbose) params compiler getCommandLine() println()
            
            code := params compiler launch()    
                
            if(code != 0) {
                fprintf(stderr, "C compiler failed, aborting compilation process\n")
                return code 
            }
            
            if(archive) archive add(module)
            
        } else {
            if(params veryVerbose) printf("Skipping %s, unchanged source.\n", cPath)
        }
        
        return 0
        
    }
    
    /**
       Get all the flags from uses in 
     */
    getFlagsFromUse: func ~sourceFolder (sourceFolder: SourceFolder) -> List<String> {
        
        flagsDone := ArrayList<String> new()
        usesDone := ArrayList<UseDef> new() 
        
        for(module in sourceFolder modules) {
            for(use1 in module uses) {
                useDef := use1 getUseDef() 
                getFlagsFromUse(useDef, flagsDone, usesDone) 
            }
        }
        
        
        flagsDone
    }

	initCompiler: func (compiler: AbstractCompiler) {
		compiler reset()
		
		if(params debug) params compiler setDebugEnabled()      
        params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())
        params compiler addIncludePath(params outPath getPath())
		
		for(compilerArg in params compilerArgs) {
            params compiler addObjectFile(compilerArg)
        }
	}

    /**
       Collect all modules imported from `module`, sort them by SourceFolder,
       put them in `toCompile`, and return it.
     */
	collectDeps: func (module: Module, toCompile: HashMap<String, SourceFolder>, done: ArrayList<String>) -> HashMap<String, SourceFolder> {
		
        name := File new(File new(module getPathElement()) getAbsolutePath()) name()
        
        sourceFolder := toCompile get(name)
        if(sourceFolder == null) {
            sourceFolder = SourceFolder new(name, params)
            toCompile put(name, sourceFolder)
        }
        
		sourceFolder modules add(module)    
		done add(module getPath())
		
		for(import1 in module getAllImports()) {
			if(done contains(import1 getModule() getPath())) continue
			collectDeps(import1 getModule(), toCompile, done)    
		}
		
		return toCompile    
		
	}
	
}
