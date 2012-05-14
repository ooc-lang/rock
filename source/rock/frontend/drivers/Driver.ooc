import io/[File]
import structs/[List, ArrayList]

import ../[BuildParams,CommandLine], ../pkgconfig/[PkgInfo, PkgConfigFrontend]
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

    compile: abstract func (module: Module) -> Int

    copyLocalHeaders: func (module: Module, params: BuildParams, done: List<Module>) {

        if(done contains?(module)) return
        done add(module)

        for(inc: Include in module includes) {
            if(inc mode == IncludeMode QUOTED) {
                destPath := params outPath path 
                
                path := module path + ".ooc"
                pathElement := params sourcePath getFile(path) parent()

                File new(pathElement, inc path) copyTo(
                File new(destPath,    inc path))
            }
        }

        for(imp: Import in module getAllImports()) {
            copyLocalHeaders(imp getModule(), params, done)
        }

    }

    addDeps: func (module: Module, toCompile: List<Module>, done: List<String>) {

        toCompile add(module)
        done add(module fullName)

        objFile := params outPath path + File separator + module getPath(".c")
        params compiler addObjectFile(objFile)

        for(imp: Import in module getAllImports()) {
            if(!done contains?(imp getModule() fullName)) {
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

        if(modulesDone contains?(module)) return
        modulesDone add(module)

        for(use1: Use in module getUses()) {
            getFlagsFromUse(use1 useDef, flagsDone, usesDone)
        }

        for(imp: Import in module getAllImports()) {
            getFlagsFromUse(imp module, flagsDone, modulesDone, usesDone)
        }

    }

    addFlag: func (flags: List<String>, flag: String) {
        if (!flags contains?(flag)) flags add(flag)
    }

    getFlagsFromUse: func (useDef: UseDef, flagsDone : List<String>, usesDone: List<UseDef>) {

        if(useDef == null) return

        if(usesDone contains?(useDef)) return
        usesDone add(useDef)

        flagsDone addAll(useDef libs)

        for(pkg in useDef pkgs) {
            info := PkgConfigFrontend getInfo(pkg)

            for(cflag in info cflags) {
                addFlag(flagsDone, cflag)
            }

            for(library in info libraries) {
                addFlag(flagsDone, "-l"+library)
            }

            for(libPath in info libPaths) {
                addFlag(flagsDone, "-L"+libPath)
            }
        }

        for(includePath in useDef includePaths) {
            addFlag(flagsDone, "-I" + includePath)
        }

        for(libPath in useDef libPaths) {
            addFlag(flagsDone, "-L" + libPath)
        }

        for(req in useDef requirements) {
            getFlagsFromUse(req useDef, flagsDone, usesDone)
        }

    }

}
