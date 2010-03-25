import io/File
import structs/[List, ArrayList]
import ../[BuildParams, Target]
import ../../middle/Module
import Driver

CombineDriver: class extends Driver {

    init: func (.params) { super(params) }

    compile: func (module: Module) -> Int {
        
        params compiler reset()
        
        copyLocalHeaders(module, params, ArrayList<Module> new())
        
        if(params debug) params compiler setDebugEnabled()      
        params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())
        params compiler addIncludePath(params outPath getPath())
        addDeps(module, ArrayList<Module> new(), ArrayList<String> new())
        
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
        
        if(params link) {
            if (params binaryPath != "") {
                params compiler setOutputPath(params binaryPath)
            } else {
                params compiler setOutputPath(module simpleName)
            }
            libs := getFlagsFromUse(module)
            for(lib in libs) {
                //printf("[CombineDriver] Adding lib %s from use\n", lib)
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
        } else {
            params compiler setCompileOnly()
        }
        
        if(params verbose) println(params compiler getCommandLine())
        
        code := params compiler launch()
        if(code != 0) {
            fprintf(stderr, "C compiler failed, aborting compilation process\n")
        }
        return code
        
    }
    
}
