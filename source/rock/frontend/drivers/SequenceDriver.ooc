
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
    }

    compile: func (module: Module) -> Int {
        pool parallelism = params parallelism

        copyLocalHeaders(module, params, ArrayList<Module> new())

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())
        reGenerated := HashMap<SourceFolder, List<Module>> new()

        // step 1: generate C sources
        if (params verbose) {
            "Generating C sources..." println()
        }
        for (sourceFolder in sourceFolders) {
            reGenerated put(sourceFolder, prepareSourceFolder(sourceFolder))
        }

        // step 2: compile
        if (params verbose) {
            "Compiling (-j %d)..." printfln(pool parallelism)
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
            code := buildSourceFolder(sourceFolder, reGenerated get(sourceFolder))
            if(code != 0) return code
        }
        if(params verbose) println()

        code := pool waitAll()
        if (code != 0) {
            // failed, can stop launching jobs now
            return code
        }

        // step 3: archive
        for (sourceFolder in sourceFolders) {
            archive := sourceFolder archive
            archive save(params, false, true)
        }

        // step 4: link
        if (params verbose) {
            "Linking..." println()
        }

        if (params link) {
            binaryPath := params getBinaryPath(module simpleName)
            binaryName := File new(binaryPath) name

            // step 4 a: create a thin archive with a symbol table
            outlib := File new(params libcachePath, binaryName + ".a") getPath()
            archive := Archive new(binaryName, outlib, params, false, null)
            for(sourceFolder in sourceFolders) {
                archive add(sourceFolder archive)
            }
            archive save(params, true, true)

            // step 4 b: link that big thin archive
            flags := Flags new(binaryPath, params)

            flags absorb(params)
            for (sourceFolder in sourceFolders) {
                flags absorb(sourceFolder)
            }
            flags addObject(archive outlib)

            code := params compiler launchLinker(flags, params linker) wait()
            if (code != 0) {
                return code
            }
        }

        return 0
    }

    /**
       Build a source folder into object files or a static library
     */
    prepareSourceFolder: func (sourceFolder: SourceFolder) -> List<Module> {

        archive := sourceFolder archive
        if(archive exists?) {
            // only regenerate dirty modules
            dirtyModules := archive dirtyModules(sourceFolder modules)
            for(module in dirtyModules) {
                CGenerator new(params, module) write()
            }
            return dirtyModules
        }

        // generate all dirty modules
        reGenerated := ArrayList<Module> new()

        for(module in sourceFolder modules) {
            CGenerator new(params, module) write()
            if(params veryVerbose) {
                ("Re-generated " + module fullName) println()
            }
            reGenerated add(module)
        }
        return reGenerated

    }

    /**
       Build a source folder into object files or a static library
     */
    buildSourceFolder: func (sourceFolder: SourceFolder, reGenerated: List<Module>) -> Int {
        if (reGenerated empty?()) {
            return 0
        }

        if(params verbose) {
            "\n%d new/updated modules to compile" printfln(reGenerated size)
        }

        for(module in reGenerated) {
            code := buildIndividual(module, sourceFolder, true)
            if(code != 0) {
                return code
            }
        }

        0

    }

    /**
     * Build an individual ooc module to its .o file
     */
    buildIndividual: func (module: Module, sourceFolder: SourceFolder, force: Bool) -> Int {

        path := File new(params outPath, module getPath("")) getPath()
        cFile := File new(path + ".c")
        oFile := File new(params outPath, module path replaceAll(File separator, '_') + ".o")

        archive := sourceFolder archive
        archiveDate := (archive ? File new(archive outlib) lastModified() : oFile lastModified())
        if(force || cFile lastModified() > archiveDate) {
            if(params veryVerbose || params debugLibcache) {
              "%s not in cache or out of date, (re)compiling" printfln(module getFullName())
            }

            flags := Flags new(oFile path, params)
            flags addObject(cFile path)
            flags absorb(params)
            flags absorb(sourceFolder)
            flags absorb(module)

            process := params compiler launchCompiler(flags)
            code := pool add(ModuleJob new(process, module, archive))
            if (code != 0) {
                // a process failed, can stop launching jobs now
                return code
            }
        } else {
            if(params veryVerbose || params debugLibcache) {
              "Skipping %s, unchanged source.\n" printfln(module getFullName())
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

