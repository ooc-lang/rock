
// sdk stuff
import io/File
import os/[Terminal, Process, JobPool]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, Archive, SourceFolder, Flags, CCompiler

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, UseDef]
import rock/backend/cnaughty/CGenerator

/**
 * Default compilation driver: handles launching C compiler
 * jobs, knows what's up-to-date and what needs to be recompiled,
 * in short, as far as you're concerned, God itself.
 * 
 * :author: Amos Wenger (nddrylliog)
 */

SequenceDriver: class extends Driver {

    sourceFolders: HashMap<String, SourceFolder>
    pool := JobPool new()

    init: func (.params) {
        super(params)
        pool parallelism = params parallelism
    }

    compile: func (module: Module) -> Int {
        if (params verbose) {
            "Sequence driver, parallelism = %d" printfln(pool parallelism)
        }

        copyLocalHeaders(module, params, ArrayList<Module> new())

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())

        oPaths := ArrayList<String> new()
        reGenerated := HashMap<SourceFolder, List<Module>> new()

        for (sourceFolder in sourceFolders) {
            reGenerated put(sourceFolder, prepareSourceFolder(sourceFolder, oPaths))
        }

        for (sourceFolder in sourceFolders) {
            if(params verbose) {
                // generate random colors for every source folder
                hash := ac_X31_hash(sourceFolder identifier) + 42
                Terminal setFgColor(Color fromHash(hash))
                if(hash & 0b01) Terminal setAttr(Attr bright)
                "%s, " printf(sourceFolder identifier)
                Terminal reset()
                fflush(stdout)
            }
            code := buildSourceFolder(sourceFolder, oPaths, reGenerated get(sourceFolder))
            if(code != 0) return code
        }
        if(params verbose) println()

        code := pool waitAll()
        if (code != 0) {
            // failed, can stop launching jobs now
            return code
        }

        for (sourceFolder in sourceFolders) {
            archive := sourceFolder archive

            if(params libcache) {
                // now build static libraries for all source folders
                if(params veryVerbose || params debugLibcache) "Saving to library %s\n" printfln(sourceFolder outlib)
                archive save(params)
            }
        }

        if (params link) {
            binaryPath := params binaryPath
            if (binaryPath == "") {
                checkBinaryNameCollision(module simpleName)
                binaryPath = module simpleName
            }

            flags := Flags new(binaryPath)

            flags absorb(params)
            for (sourceFolder in sourceFolders) {
                flags absorb(sourceFolder)
            }
            for(oPath in oPaths) {
                flags addObject(oPath)
            }

            if(params linker != null) {
                Exception new("[stub] Custom linker in BuildParams") throw()
            }

            code := params compiler launch(flags) wait()
            if (code != 0) {
                return code
            }
        }

        return 0
    }

    /**
       Build a source folder into object files or a static library
     */
    prepareSourceFolder: func (sourceFolder: SourceFolder, objectFiles: List<String>) -> List<Module> {

        archive := sourceFolder archive

        // if lib-caching, we compile every object file to a .a static lib
        if(params libcache) {
            objectFiles add(sourceFolder outlib)

            if(archive exists?) {
                dirtyModules := archive dirtyModules(sourceFolder modules)
                for(module in dirtyModules) {
                    CGenerator new(params, module) write()
                }
                return dirtyModules
            }
        }

        oPaths := ArrayList<String> new()
        if(params verbose) "Re-generating modules..." println()
        reGenerated := ArrayList<Module> new()
        for(module in sourceFolder modules) {
            result := CGenerator new(params, module) write()
            
            if(result && params verbose) ("Re-generated " + module fullName) println()
            
            if(result) {
                reGenerated add(module)
            } else {
                // already compiled, but still need to link with it
                underPath := module path replaceAll(File separator, '_')
                oPath := File new(params outPath, underPath) getPath() + ".o"
                objectFiles add(oPath)
            }
        }
        
        if(params verbose) {
            if(reGenerated empty?()) {
                "No files generated." println()
            } else {
                "%d files generated." printfln(reGenerated size)
            }
        }

        return reGenerated

    }

    /**
       Build a source folder into object files or a static library
     */
    buildSourceFolder: func (sourceFolder: SourceFolder, objectFiles: List<String>,
      reGenerated: List<Module>) -> Int {

        archive := sourceFolder archive

        // if lib-caching, we compile every object file to a .a static lib
        if(params libcache) {
            objectFiles add(sourceFolder outlib)

            if(reGenerated getSize() > 0) {
                if(params verbose) printf("\n%d new/updated modules to compile\n", reGenerated getSize())
                for(module in reGenerated) {
                    code := buildIndividual(module, sourceFolder, null, archive, true)
                    if(code != 0) return code
                }
            }
        } else {
            if(params verbose) printf("Compiling regenerated modules...\n")
            for(module in reGenerated) {
                code := buildIndividual(module, sourceFolder, objectFiles, null, false)
                if(code != 0) return code
            }
        }

        0

    }

    /**
       Build an individual ooc files to its .o file, add it to oPaths
     */
    buildIndividual: func (module: Module, sourceFolder: SourceFolder,
        oPaths: List<String>, archive: Archive, force: Bool) -> Int {

        path := File new(params outPath, module getPath("")) getPath()
        oPath := File new(params outPath, module path replaceAll(File separator, '_')) getPath() + ".o"
        cPath := path + ".c"
        if(oPaths) {
            oPaths add(oPath)
        }

        cFile := File new(cPath)
        oFile := File new(oPath)

        archiveDate := (archive ? File new(archive outlib) lastModified() : oFile lastModified())
        if(force || cFile lastModified() > archiveDate) {
            if(params veryVerbose || params debugLibcache) {
              "%s not in cache or out of date, (re)compiling" printfln(module getFullName())
            }

            flags := Flags new(cPath)
            flags addObject(oPath)
            flags absorb(params)
            flags absorb(sourceFolder)

            process := params compiler launch(flags)
            code := pool add(ModuleJob new(process, module, archive))
            if (code != 0) {
                // a process failed, can stop launching jobs now
                return code
            }
        } else {
            if(params veryVerbose || params debugLibcache) {
              "Skipping %s, unchanged source.\n" printfln(cPath)
            }
        }

        return 0

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
            name := File new(absolutePath) name()
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

/**
 * The sequence driver uses special jobs: module jobs. They
 * remember which module and archive they belong to, so that they
 * can add themselves to a .a file when needed.
 *
 * :author: Amos Wenger (nddrylliog)
 */

ModuleJob: class extends Job {

    module: Module
    archive: Archive

    init: func (.process, =module, =archive) {
      super(process)
    }

    onExit: func (code: Int) {
        if (code != 0) {
          "C compiler failed (got code %d), aborting compilation process" printfln(code)
          return
        }

        if (archive) {
          archive add(module)
        }
    }

}

