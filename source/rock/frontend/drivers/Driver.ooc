
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
 * Drives the compilation process, e.g. chooses in which order
 * files are compiled, optionally checks for timestamps and stuff.
 */
Driver: abstract class {

    params: BuildParams

    init: func(=params) {}

    compile: abstract func (module: Module) -> Int

    copyLocals: func (module: Module, params: BuildParams,
        done := ArrayList<Module> new(), usesDone := ArrayList<UseDef> new()) {

        if(done contains?(module)) return
        done add(module)

        path := module path + ".ooc"
        (candidate, element) := params sourcePath getFile(path)

        if (candidate) {
            pathElement := candidate parent

            for(inc: Include in module includes) {
                if(inc mode == IncludeMode LOCAL) {
                    base := params libcache ? params libcachePath : params outPath path
                    if (doublePrefix()) {
                        base = File new(base, module getUseDef() identifier) path
                    }

                    destDir := File new(base, module getSourceFolderName())

                    src  := File new(pathElement, inc path + ".h") 
                    dest := File new(destDir,     inc path + ".h")
                    
                    if (params verboser) {
                        "Copying %s to %s" printfln(src path, dest path)
                    }
                    src copyTo(dest)
                }
            }
        } else {
            if (!module dummy) {
                raise("Can't find module %s in the sourcepath" format(module fullName))
            }
        }

        for(imp: Import in module getAllImports()) {
            copyLocals(imp getModule(), params, done, usesDone)
        }

        usedefCollection := ArrayList<UseDef> new()
        for(uze: Use in module getUses()) {
            usedefCollection add(uze useDef)
            walkUseDef(uze useDef, usedefCollection)
        }
        
        for(useDef: UseDef in usedefCollection) {
            if (usesDone contains?(useDef)) {
                continue
            }
            usesDone add(useDef)

            props := useDef getRelevantProperties(params)
            for (additional in props additionals) {
                src := additional absolute

                base := params libcachePath
                if (doublePrefix()) {
                    base = File new(base, useDef identifier) path
                }

                destDir := File new(base, useDef identifier)
                dest := File new(destDir, additional relative)

                if (params verboser) {
                    "Copying %s to %s" printfln(src path, dest path)
                }
                src copyTo(dest)
            }
        }

    }

    walkUseDef: func(u: UseDef, usedefCollection: ArrayList<UseDef> = ArrayList<UseDef> new()) -> ArrayList<UseDef> {
        for(req in u requirements){
            if(!usedefCollection contains?(req useDef)){
                usedefCollection add(req useDef)
                walkUseDef(req useDef, usedefCollection)
            }
        }
        return usedefCollection
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

            uze := params sourcePathTable get(pathElement)
            identifier := uze ? uze identifier : name

            sourceFolder := toCompile get(identifier)
            if(sourceFolder == null) {
                sourceFolder = SourceFolder new(name, module getPathElement(), identifier, params, uze)
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

    doublePrefix: func -> Bool {
        false
    }

}
