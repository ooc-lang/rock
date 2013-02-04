
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

        copyLocals(module, params)

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())
        dirtyModules := HashMap<SourceFolder, List<Module>> new()

        // step 1: generate C sources
        if (params verbose) {
            "Generating C sources..." println()
        }
        for (sourceFolder in sourceFolders) {
            dirtyModules put(sourceFolder, generateSources(sourceFolder))
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
            code := buildSourceFolder(sourceFolder, dirtyModules get(sourceFolder))
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
        if (params link) {
            if (params verbose) {
                "Linking..." println()
            }

            code := link(module)
            if (code != 0) {
                return code
            }
        }

        return 0
    }

    link: func (module: Module) -> Int {
        binaryPath := params getBinaryPath(module simpleName)
        binaryName := File new(binaryPath) name

        // step 4 b: link that big thin archive
        flags := Flags new(binaryPath, params)

        flags absorb(params)
        for (sourceFolder in sourceFolders) {
            flags absorb(sourceFolder)
        }

        intermediateArchive := true
        version (apple) {
            // Apple's BSD-like toolchain doesn't give a shit
            // about library order, but god forbid you should try
            // to do nested/thin archives. Oh, no.
            intermediateArchive = false
        }

        if (intermediateArchive) {
            // create a thin archive with a symbol table - MinGW's linker
            // will complain otherwise.
            outlib := File new(params libcachePath, binaryName + ".a") getPath()
            archive := Archive new(null, outlib, params, false, null)
            for(sourceFolder in sourceFolders) {
                archive add(sourceFolder archive)
            }
            archive save(params, true, true)
            flags addObject(archive outlib)
        } else {
            // not on Windows? Modern Linux/OSX linkers will accept static
            // libraries in any order, let's blissfully go ahead.
            for(sourceFolder in sourceFolders) {
                flags addObject(sourceFolder archive)
            }
        }

        params compiler launchLinker(flags, params linker) wait()
    }

    /**
       Build a source folder into object files or a static library
     */
    generateSources: func (sourceFolder: SourceFolder) -> List<Module> {

        dirtyModules := ArrayList<Module> new()

        archive := sourceFolder archive
        if(archive exists?) {
            dirtyModules addAll(archive dirtyModules())
        } else {
            // on first compile, we have no archive info
            dirtyModules addAll(sourceFolder modules)
        }

        for(module in dirtyModules) {
            CGenerator new(params, module) write()
        }
        dirtyModules

    }

    /**
       Build a source folder into object files or a static library
     */
    buildSourceFolder: func (sourceFolder: SourceFolder, dirtyModules: List<Module>) -> Int {
        if (dirtyModules empty?()) {
            return 0
        }

        if(params verbose) {
            "\n%d new/updated modules to compile" printfln(dirtyModules size)
        }

        for(module in dirtyModules) {
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
        oFile := File new(params libcachePath, sourceFolder relativeObjectPath(module))

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
            code := pool add(ModuleJob new(process, module, archive, oFile path))
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
    objectPath: String

    init: func (.process, =module, =archive, =objectPath) {
      super(process)
    }

    onExit: func (code: Int) {
        if (code != 0) {
          "C compiler failed (got code %d), aborting compilation process" printfln(code)
          return
        }

        if (archive) {
          archive add(module, objectPath)
        }
    }

}

