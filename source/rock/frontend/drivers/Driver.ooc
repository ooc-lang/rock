import io/[File]
import structs/[List, ArrayList]

import ../BuildParams, ../pkgconfig/[PkgInfo, PkgConfigFrontend]
import ../../middle/[Import, Include, Module, Use, UseDef]

import ../../utils/[ShellUtils]

/**
   Drives the compilation process, e.g. chooses in which order
   files are compiled, optionally checks for timestamps and stuff.

   :author: Amos Wenger (nddrylliog)
 */
Driver: abstract class {

    params: BuildParams

    init: func(=params) {}

    // Called before code generation, leaves a chance to the driver to adjust the params themselves
    setup: func {}

    compile: abstract func (module: Module) -> Int

    copyLocalHeaders: func (module: Module, params: BuildParams, done: List<Module>) {

        if(done contains(module)) return
        done add(module)
        for(inc: Include in module includes) {
            if(inc mode == IncludeModes LOCAL) {
                path := module path + ".ooc"
                pathElement := params sourcePath getFile(path) parent()
                File new(pathElement,    inc path + ".h") copyTo(
                File new(params outPath, inc path + ".h"))
            }
        }

        for(imp: Import in module getAllImports()) {
            copyLocalHeaders(imp module, params, done)
        }

    }

    addDeps: func (module: Module, toCompile: List<Module>, done: List<String>) {

        toCompile add(module)
        done add(module fullName)

        objFile := params getOutputPath(module, ".c")
        params compiler addObjectFile(objFile)

        for(imp: Import in module getAllImports()) {
            if(!done contains(imp getModule() fullName)) {
                addDeps(imp getModule(), toCompile, done)
            }
        }

    }

    getFlagsFromUse: func ~defaults (module: Module) -> List<String> {

        flagsDone := ArrayList<String> new()
        modulesDone := ArrayList<Module> new()
        getFlagsFromUse(module, flagsDone, modulesDone, ArrayList<UseDef> new())
        return flagsDone

    }

    getFlagsFromUse: func ~allModules (module: Module, flagsDone: List<String>, modulesDone: List<Module>, usesDone: List<UseDef>) {

        if(modulesDone contains(module)) return
        modulesDone add(module)

        for(use1: Use in module getUses()) {
            useDef := use1 getUseDef()
            getFlagsFromUse(useDef, flagsDone, usesDone)
        }

        for(imp: Import in module getAllImports()) {
            getFlagsFromUse(imp module, flagsDone, modulesDone, usesDone)
        }

    }

    getFlagsFromUse: func (useDef: UseDef, flagsDone : List<String>, usesDone: List<UseDef>) {

        // hacky workaround, but seriously, wtf?
        if(useDef == null) return

        if(usesDone contains(useDef)) return
        usesDone add(useDef)

        //compileNasms(useDef getLibs(), flagsDone)
        flagsDone addAll(useDef getLibs())

        for(pkg in useDef getPkgs()) {
            info := PkgConfigFrontend getInfo(pkg)
            for(cflag in info cflags) {
                if(!flagsDone contains(cflag)) {
                    flagsDone add(cflag)
                }
            }
            for(library in info libraries) {
                // FIXME lazy
                lpath := "-l"+library
                if(!flagsDone contains(lpath)) {
                    flagsDone add(lpath)
                }
            }
        }

        for(includePath in useDef getIncludePaths()) {
            // FIXME lazy too
            ipath := "-I" + includePath
            if(!flagsDone contains(ipath)) {
                flagsDone add(ipath)
            }
        }

        for(libPath in useDef getLibPaths()) {
            // FIXME lazy too
            lpath := "-L" + libPath
            if(!flagsDone contains(lpath)) {
                flagsDone add(lpath)
            }
        }

        for(req in useDef getRequirements()) {
            getFlagsFromUse(req getUseDef(), flagsDone, usesDone)
        }

    }

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
