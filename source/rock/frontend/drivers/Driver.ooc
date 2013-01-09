import io/[File]
import structs/[List, ArrayList, HashMap]

import ../[BuildParams,CommandLine], ../pkgconfig/[PkgInfo, PkgConfigFrontend]
import ../../middle/[Import, Include, Module, Use, UseDef]
import ../../frontend/Target

import os/ShellUtils

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
