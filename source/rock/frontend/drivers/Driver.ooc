import io/[File]
import structs/[List, ArrayList]

import ../BuildParams
import ../../middle/[Import, Include, Module, Use]

/*
import org.ooc.frontend.pkgconfig.PkgConfigFrontend 
import org.ooc.frontend.pkgconfig.PkgInfo 
import org.ooc.middle.UseDef 
import org.ooc.middle.UseDef.Requirement 
*/

import ../../utils/[ShellUtils]

/**
 * Drives the compilation process, e.g. chooses in which order
 * files are compiled, optionally checks for timestamps and stuff.
 * Great fun.
 * 
 * @author Amos Wenger
 */
Driver: abstract class {

    params: BuildParams
    additionals  := ArrayList<String> new() 
    compilerArgs := ArrayList<String> new() 
    
    init: func(=params) {}
    
    compile: abstract func (module: Module) -> Int
    
    copyLocalHeaders: func (module: Module, params: BuildParams, done: List<Module>) {
        
        if(done contains(module)) return 
        done add(module) 
        for(inc: Include in module includes) {
            if(inc mode == IncludeModes LOCAL) {
                path := module fullName + ".ooc"
                pathElement := params sourcePath getFile(path) parent() 
                File new(pathElement,    inc path + ".h") copyTo(
                File new(params outPath, inc path + ".h")) 
            }
        }
        
        for(imp: Import in module imports) {
            copyLocalHeaders(imp module, params, done) 
        }
        
    }
    
    addDeps: func (module: Module, toCompile: List<Module>, done: List<String>) {
        
        toCompile add(module) 
        done add(module fullName) 
        
        objFile := params outPath path + File separator + module getOutPath(".c")
        params compiler addObjectFile(objFile) 
        
        for(imp: Import in module imports) {
            if(!done contains(imp module fullName)) {
                addDeps(imp module, toCompile, done) 
            }
        }
        
    }
    
    /*
    getFlagsFromUse: func (module: Module) -> List<String> {

        list := ArrayList<String> new() 
        done := ArrayList<Module> new() 
        getFlagsFromUse(module, list, done, ArrayList<UseDef> new()) 
        return list 
        
    }

    getFlagsFromUse: func (module: Module, flagsDone: List<String>, 
            modulesDone: List<Module>, usesDone: List<UseDef>) {

        if(modulesDone contains(module)) return 
        modulesDone add(module) 
        
        for(use1: Use in module getUses()) {
            UseDef useDef = use1 getUseDef() 
            getFlagsFromUse(useDef, flagsDone, usesDone) 
        }
        
        for(imp: Import in module imports) {
            getFlagsFromUse(imp module, flagsDone, modulesDone, usesDone) 
        }
        
    }

    getFlagsFromUse: func (useDef: UseDef, flagsDone : List<String>,
            usesDone: List<UseDef>) {
        
        if(usesDone contains(useDef)) return 
        usesDone add(useDef) 
        compileNasms(useDef getLibs(), flagsDone) 
        for(pkg: String in useDef getPkgs()) {
            PkgInfo info = PkgConfigFrontend getInfo(pkg) 
            for(cflag: String in info cflags) {
                if(!flagsDone contains(cflag)) {
                    flagsDone add(cflag) 
                }
            }
            for(library: String in info libraries) {
                 // FIXME lazy
                String lpath = "-l"+library 
                if(!flagsDone contains(lpath)) {
                    flagsDone add(lpath) 
                }
            }
        }
        for(includePath: String in useDef getIncludePaths()) {
             // FIXME lazy too 
            ipath := "-I" + includePath 
            if(!flagsDone contains(ipath)) {
                flagsDone add(ipath) 
            }
        }
        
        for(libPath: String in useDef getLibPaths()) {
             // FIXME lazy too 
            lpath := "-L" + libPath 
            if(!flagsDone contains(lpath)) {
                flagsDone add(lpath) 
            }
        }
        
        for(req: Requirement in useDef getRequirements()) {
            getFlagsFromUse(req getUseDef(), flagsDone, usesDone) 
        }
        
    }
    */
    
    findExec: func (name: String) -> File {
        
        execFile := ShellUtils findExecutable(name, false) 
        if(!execFile) {
            execFile = ShellUtils findExecutable(name + ".exe", false) 
        }
        if(!execFile) {
            Exception new(This, "Executable " + name + " not found :/")  throw()
        }
        return execFile 
        
    }
    
}
