
// sdk stuff
import io/[File]
import structs/[List, ArrayList, HashMap]
import os/ShellUtils

// our stuff
import rock/frontend/[BuildParams, Target, CommandLine]
import rock/frontend/pkgconfig/[PkgInfo, PkgConfigFrontend]
import rock/middle/[Import, Include, Module, Use, UseDef]
import SourceFolder

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
                pathElement := params sourcePath getFile(path) parent

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

    /**
       Collect all modules imported from `module`, sort them by SourceFolder,
       put them in `toCompile`, and return it.
     */
    collectDeps: func (module: Module, toCompile: HashMap<String, SourceFolder>,
        done: ArrayList<Module>) -> HashMap<String, SourceFolder> {

        if(!module dummy) {
            pathElement := module getPathElement()
            absolutePath := File new(pathElement) getAbsolutePath()
            name := File new(absolutePath) name
            identifier := params sourcePathTable get(pathElement)
            if (!identifier) {
                identifier = name
            }

            sourceFolder := toCompile get(identifier)
            if(sourceFolder == null) {
                sourceFolder = SourceFolder new(name, module getPathElement(), identifier, params)
                toCompile put(sourceFolder identifier, sourceFolder)
            }
            sourceFolder modules add(module)
        }
        done add(module)

        for(import1 in module getAllImports()) {
            if(done contains?(import1 getModule())) continue
            collectDeps(import1 getModule(), toCompile, done)
        }

        return toCompile

    }

}
