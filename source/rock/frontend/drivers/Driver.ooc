
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

    copyLocals: func (module: Module, params: BuildParams, done := ArrayList<Module> new(), usesDone := ArrayList<UseDef> new()) {

        if(done contains?(module)) return
        done add(module)

        path := module path + ".ooc"
        pathElement := params sourcePath getFile(path) parent

        for(inc: Include in module includes) {
            if(inc mode == IncludeModes LOCAL) {
                dest := (params libcache) ? \
                    File new(params libcachePath, module getSourceFolderName()) : \
                    params outPath

                File new(pathElement, inc path + ".h") copyTo(
                File new(dest,        inc path + ".h"))
            }
        }

        for(imp: Import in module getAllImports()) {
            copyLocals(imp getModule(), params, done, usesDone)
        }
        
        for(uze: Use in module getUses()) {
            useDef := uze useDef
            if (usesDone contains?(useDef)) {
                continue
            }
            usesDone add(useDef)

            for (additional in useDef getAdditionals()) {
                src := File new(additional)
                dest := File new(params libcachePath, src getName())

                "Copying %s to %s" printfln(src path, dest path)
                src copyTo(dest)
            }
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

    collectUses: func ~sourceFolders (sourceFolder: SourceFolder, \
            modulesDone := ArrayList<Module> new(), usesDone := ArrayList<UseDef> new()) -> List<UseDef> {
        for (module in sourceFolder modules) {
            collectUses(module, modulesDone, usesDone)
        }

        usesDone
    }

    collectUses: func ~modules (module: Module, \
            modulesDone := ArrayList<Module> new(), usesDone := ArrayList<UseDef> new()) -> List<UseDef> {
        if (modulesDone contains?(module)) {
            return usesDone
        }
        modulesDone add(module)
        
        for (uze in module getUses()) {
            useDef := uze useDef
            if (!usesDone contains?(useDef)) {
                usesDone add(useDef)
            }
        }

        for (imp in module getAllImports()) {
            collectUses(imp getModule(), modulesDone, usesDone)
        }

        usesDone
    }

}
