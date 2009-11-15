import io/File
import structs/[List, ArrayList]
import ../[BuildParams]
import ../Target
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
        for(dynamicLib: String in params dynamicLibs) {
            params compiler addDynamicLibrary(dynamicLib)
        }
        for(additional: String in additionals) {
            params compiler addObjectFile(additional)
        }
        for(compilerArg: String in compilerArgs) {
            params compiler addObjectFile(compilerArg)
        }
        
		// perhaps these should be per-compiler overrides but GCC and clang
		// both accept these flags
		for (arch: String in params fatArchitectures) {
			params compiler addOption("-arch")
			params compiler addOption(arch)
		}

		if (params osxSDKAndDeploymentTarget != null) {
			params compiler addOption("-isysroot");
			params compiler addOption("/Developer/SDKs/MacOSX" + params osxSDKAndDeploymentTarget + ".sdk");
			params compiler addOption("-mmacosx-version-min=" + params osxSDKAndDeploymentTarget);
		}

        if(params link) {
            params compiler setOutputPath(module simpleName)
            //libs := getFlagsFromUse(module)
            //for(lib: String in libs) params compiler addObjectFile(lib)
            
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
