import io/[File]
import structs/[List, ArrayList, HashMap]

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

    customPkgCache := HashMap<CustomPkg, PkgInfo> new()

    init: func(=params) {}

    compile: abstract func (module: Module) -> Int

    copyLocalHeaders: func (module: Module, params: BuildParams, done: List<Module>) {

        if(done contains?(module)) return
        done add(module)

        for(inc: Include in module includes) {
            if(inc mode == IncludeModes LOCAL) {
                destPath := (params libcache) ? \
                    params libcachePath + File separator + module getSourceFolderName() : \
                    params outPath path

                path := module path + ".ooc"
                pathElement := params sourcePath getFile(path) parent()

                File new(pathElement, inc path + ".h") copyTo(
                File new(destPath,    inc path + ".h"))
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

    getFlagsFromUse: func (useDef: UseDef, flagsDone : List<String>, usesDone: List<UseDef>) {

        if(usesDone contains?(useDef)) return
        usesDone add(useDef)

        flagsDone addAll(useDef getLibs())

        applyInfo := func (info: PkgInfo) {
            for(cflag in info cflags) {
                if(!flagsDone contains?(cflag)) {
                    flagsDone add(cflag)
                }
            }
            for(library in info libraries) {
                // In theory this is bad because different compiles might
                // have diferent flags. We used to have a slew of fixmes
                // here but now they're gone. Sad panda.
                lpath := "-l"+library
                if(!flagsDone contains?(lpath)) {
                    flagsDone add(lpath)
                }
            }
            for(libPath in info libPaths) {
                lpath := "-L"+libPath
                if(!flagsDone contains?(lpath)) {
                    flagsDone add(lpath)
                }
            }
        }

        for(pkg in useDef getPkgs()) {
            info := PkgConfigFrontend getInfo(pkg)
            applyInfo(info)
        }

        for(pkg in useDef getCustomPkgs()) {
            info: PkgInfo
            if (customPkgCache contains?(pkg)) {
                info = customPkgCache get(pkg)
            } else {
                info = PkgConfigFrontend getCustomInfo(
                    pkg utilName, pkg names,
                    pkg cflagArgs, pkg libsArgs
                )
                customPkgCache put(pkg, info)
            }
            applyInfo(info)
        }

        for(includePath in useDef getIncludePaths()) {
            ipath := "-I" + includePath
            if(!flagsDone contains?(ipath)) {
                flagsDone add(ipath)
            }
        }

        for(libPath in useDef getLibPaths()) {
            lpath := "-L" + libPath
            if(!flagsDone contains?(lpath)) {
                flagsDone add(lpath)
            }
        }

        for(req in useDef getRequirements()) {
            getFlagsFromUse(req useDef, flagsDone, usesDone)
        }

    }

    isLinkerFlag: func (flag: String) -> Bool {
        flag startsWith?("-L") || flag startsWith?("-l") || \
        flag startsWith?("-Wl")
    }

    findExec: func (name: String) -> File {
        ShellUtils findExecutable(name, true)
    }

    checkBinaryNameCollision: func (name: String) {
        if (File new(name) dir?()) {
            stderr write("Naming conflict (output binary) : There is already a directory called %s.\nTry a different name, e.g. '-o=%s2'\n" format(name, name))
            CommandLine failure(params)
            exit(1)
        }
    } 
}
