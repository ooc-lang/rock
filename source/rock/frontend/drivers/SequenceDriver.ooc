import io/File, os/Process, text/Buffer
import structs/[List, ArrayList]
import ../[BuildParams, Target]
import ../compilers/AbstractCompiler
import ../../middle/Module
import Driver

SequenceDriver: class extends Driver {

    init: func (.params) { super(params) }

	compile: func (module: Module) -> Int {
		
		copyLocalHeaders(module, params, ArrayList<Module> new())    
		
		if(params verbose) {
			("Sequence driver, using " + params sequenceThreads + " thread(s).") println()
		}
		
		toCompile := collectDeps(module, ArrayList<Module> new(), ArrayList<String> new())
		
        oPaths := ArrayList<String> new()
		
		for(currentModule in toCompile) {
            
            initCompiler(params compiler)    
            params compiler setCompileOnly()
            
            path := File new(params outPath, currentModule getPath("")) getPath()
            oPath := path + ".o"    
            cPath := path + ".c"    
            oPaths add(oPath)
            
            cFile := File new(cPath)
            oFile := File new(oFile)
            
            if(cFile lastModified() > oFile lastModified()) {
            
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
                for(additional in additionals) {
                    params compiler addObjectFile(additional)
                }
                for(compilerArg in compilerArgs) {
                    params compiler addObjectFile(compilerArg)
                }
                for(incPath in params incPath getPaths()) {
                    params compiler addIncludePath(incPath getAbsolutePath())
                }
                
                /*
                if(params fatArchitectures != null) {
                    params compiler setFatArchitectures(params fatArchitectures)    
                }
                if(params osxSDKAndDeploymentTarget != null) {
                    params compiler setOSXSDKAndDeploymentTarget(params osxSDKAndDeploymentTarget)    
                }
                */

                libs := getFlagsFromUse(module)
                for(lib in libs) {
                    //printf("[SequenceDriver] Adding lib %s from use\n", lib)
                    params compiler addObjectFile(lib)
                }
                
                if(params verbose) params compiler getCommandLine() println()
                
                //long tt1 = System.nanoTime()    
                code := params compiler launch()    
                //long tt2 = System.nanoTime()    
                //if(params timing) System.out.println("  (" + ((tt2 - tt1) / 1000000)+")")    
                    
                if(code != 0) {
                    fprintf(stderr, "C compiler failed, aborting compilation process\n")
                    return code 
                }
                
            } else {
                
                if(params veryVerbose) {
                    ("Skipping "+cPath+", just the same.") println()
                }
                
            }
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
            for(additional in additionals) {
                params compiler addObjectFile(additional)
            }
		
			for(libPath in params libPath getPaths()) {
				params compiler addLibraryPath(libPath getAbsolutePath())    
			}
			
            /*
			if(params fatArchitectures != null) {
				params compiler setFatArchitectures(params fatArchitectures)    
			}
			if(params osxSDKAndDeploymentTarget != null) {
				params compiler setOSXSDKAndDeploymentTarget(params osxSDKAndDeploymentTarget)    
			}
            */

			if(params binaryPath != "") {
                params compiler setOutputPath(params binaryPath)
            } else {
                params compiler setOutputPath(module simpleName)
            }
            
            libs := getFlagsFromUse(module)
            for(lib in libs) {
                //printf("[SequenceDriver] Adding lib %s from use\n", lib)
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
	
			//long tt1 = System.nanoTime()    
			code := params compiler launch()    
			//long tt2 = System.nanoTime()    
			//if(params timing) System.out.println("  (linking " + ((tt2 - tt1) / 1000000)+"ms)")    
			//if(params timing) System.out.println("(total " + ((System.nanoTime() - tt0) / 1000000)+"ms)")    
			
			if(code != 0) {
                fprintf(stderr, "C compiler failed, aborting compilation process\n")
				return code
			}
		
		}
		
		if(params outlib != null) {
			
			// TODO: make this platform-independant (for now it's a linux-friendly hack)
            args := ArrayList<String> new()
			args add("ar")      // ar = archive tool
			args add("rcs")     // r = insert files, c = create archive, s = create/update .o file index
			args add(params outlib)    
			
			allModules := collectDeps(module, ArrayList<Module> new(), ArrayList<String> new())    
			for(dep in allModules) {
				args add(File new(params outPath, dep getPath("")) getPath() + ".o")    
			}
			
			if(params verbose) {
                command := Buffer new()
                for(arg in args) {
					command append(arg) .append(" ")
				}
                command toString() println()
			}
			
            process := Process new(args)
            process getOutput() println() // not ideal, should redirect to stdin+stdout instead
			
		}
		
		
		return 0    
		
	}

	initCompiler: func (compiler: AbstractCompiler) {
		compiler reset()
		
		if(params debug) params compiler setDebugEnabled()      
        params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())
        params compiler addIncludePath(params outPath getPath())
		
		for(compilerArg in compilerArgs) {
            params compiler addObjectFile(compilerArg)
        }
	}

	collectDeps: func (module: Module, toCompile: ArrayList<Module>, done: ArrayList<Module>) -> ArrayList<Module> {
		
		toCompile add(module)    
		done add(module getPath())
		
		for(import1 in module getAllImports()) {
			if(done contains(import1 getModule() getPath())) continue    
			collectDeps(import1 getModule(), toCompile, done)    
		}
		
		return toCompile    
		
	}
	
}
