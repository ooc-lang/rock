
// sdk stuff
import io/File
import os/[Terminal, Process, JobPool, ShellUtils, Pipe]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, Archive, SourceFolder, Flags, CCompiler, DependencyGraph

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, UseDef]
import rock/backend/cnaughty/CGenerator

/**
 * Default compilation driver: handles launching C compiler
 * jobs, knows what's up-to-date and what needs to be recompiled,
 * in short, as far as you're concerned, God itself.
 */

SequenceDriver: class extends Driver {

    sourceFolders: HashMap<String, SourceFolder>
    graph: DependencyGraph

    pool := JobPool new()

    init: func (.params) {
        super(params)
    }

    compile: func (module: Module) -> Int {
        pool parallelism = params parallelism

        copyLocals(module, params)

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())
        dirtyModules := HashMap<SourceFolder, List<Module>> new()

        graph = DependencyGraph new(params, sourceFolders)
        reverseList := graph list reverse()

        // step 1: generate C sources
        if (params verbose) {
            "Generating C sources..." println()
        }
        for (sourceFolder in reverseList) {
            dirtyModules put(sourceFolder, generateSources(sourceFolder))
        }

        // step 2: compile
        if (params verbose) {
            "Compiling with %d thread%s..." printfln(pool parallelism, pool parallelism > 1 ? "s" : "")
        }
        for (sourceFolder in reverseList) {
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

        (code, failedJob) := pool waitAll()
        if (code != 0) {
            // failed, can stop launching jobs now
            return code
        }

        // step 3: archive
        for (sourceFolder in reverseList) {
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

            // step 4b: postlink?
            version (apple) {
                if (params debug?()) {
                    if (params verbose) {
                        "Merging debug symbols..." println()
                    }

                    code := dsym(module)
                    if (code != 0) {
                        return code
                    }
                }
            }
        }

        return 0
    }

    link: func (module: Module) -> Int {
        binaryPath := params getBinaryPath(module simpleName)
        if (!binaryPath) {
            return 1
        }
        binaryName := File new(binaryPath) name

        // step 4 b: link that big thin archive
        flags := Flags new(binaryPath, params)

        flags absorb(params)
        for (sourceFolder in graph list) {
            flags absorb(sourceFolder)
        }

        for(sourceFolder in graph list) {
            flags addObject(sourceFolder archive)
        }

        linkerProcess := params compiler launchLinker(flags, params linker)
        code := linkerProcess wait()
        if (code != 0 && linkerProcess stdErr) {
            // print stderr
            errOutput := PipeReader new(linkerProcess stdErr) readAll()
            stderr write("C linker failed on %s from %s, bailing out\n\n" format(module fullName, module getUseDef() identifier))
            stderr write(errOutput)
        }

        code
    }

    dsym: func (module: Module) -> Int {
        version (apple) {
            util := ShellUtils findExecutable("dsymutil", true)

            command := ArrayList<String> new()
            command add(util getPath())
            binPath := params getBinaryPath(module simpleName)
            command add(binPath)

            process := Process new(command)
            if (params verbose) {
                if (params verboser) {
                    process getCommandLine() println()
                } else {
                    "[DSYM] %s" printfln(binPath)
                }
            } else {
                process setStderr(Pipe new())
            }
            process executeNoWait()
            return process wait()
        }

        // non-OSX? all good!
        return 0
    }

    /**
       Build a source folder into object files or a static library
     */
    generateSources: func (sourceFolder: SourceFolder) -> List<Module> {

        dirtyModules := ArrayList<Module> new()

        archive := sourceFolder archive
        if(archive exists?) {
            archive updateDirtyModules()
            dirtyModules addAll(archive dirtyModules)
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
            "\nCompiling %d modules" printfln(dirtyModules size)
        }

        // step 1: compile ooc modules
        for (module in dirtyModules) {
            code := buildModule(module, sourceFolder, true)
            if(code != 0) {
                return code
            }
        }

        // step 2: compile additionals, if any
        flags := Flags new("", params)
        flags absorb(sourceFolder)

        for (uze in flags uses) {
            props := uze getRelevantProperties(params)
            for (additional in props additionals) {
                buildAdditional(sourceFolder, uze, additional)
            }
        }

        0

    }

    /**
     * Build an individual ooc module to its .o file
     */
    buildModule: func (module: Module, sourceFolder: SourceFolder, force: Bool) -> Int {

        path := module getPath()
        cFile := File new(params outPath, path + ".c")
        oFile := File new(params libcachePath, path + ".o")

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
            flags setMainModule(module)

            process := params compiler launchCompiler(flags)
            code := pool add(ModuleJob new(process, module, archive, oFile path))
            if (code != 0) {
                // a process failed we can stop launching jobs now
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
     * Build an additional (.c/.s file) to a .o
     */
    buildAdditional: func (sourceFolder: SourceFolder, uze: UseDef, additional: Additional) -> Int {

        lowerName := additional relative path toLower()
        match {
            case lowerName endsWith?(".c") =>
                // C source file, compile away
            case lowerName endsWith?(".s") =>
                // Assembly file, compile away
            case =>
                // probably just want to copy it.
                return 0
        }

        cPath := File new(File new(params libcachePath, uze identifier), additional relative) getPath()
        oPath := "%s.o" format(cPath[0..-3])

        archive := sourceFolder archive

        flags := Flags new(oPath, params)
        flags absorb(params)
        flags addObject(cPath)

        process := params compiler launchCompiler(flags)
        code := pool add(AdditionalJob new(process, archive, cPath, oPath))
        if (code != 0) {
            // a process failed, can stop launching jobs now
            return code
        }

        return 0

    }
}

/**
 * The sequence driver uses special jobs: module jobs. They
 * remember which module and archive they belong to, so that they
 * can add themselves to a .a file when needed.
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
            stderr write("C compiler failed on module %s from %s, bailing out\n\n" format(module fullName, module getUseDef() identifier))

            if (process stdErr) {
               stderr write(PipeReader new(process stdErr) readAll())
            }

            return
        }

        if (archive) {
            archive add(module, objectPath)
        }
    }

}

/**
 * Additionals are source files (.c, .s) that have
 * to be compiled separately as part of rock's regular
 * compile process and added to the sourcefolder archives.
 */

AdditionalJob: class extends Job {

    archive: Archive
    sourcePath, objectPath: String

    init: func (.process, =archive, =sourcePath, =objectPath) {
      super(process)
    }

    onExit: func (code: Int) {
        if (code != 0) {
          stderr write("C compiler failed on additional %s, bailing out\n\n" format(sourcePath))

          if (process stdErr) {
               stderr write(PipeReader new(process stdErr) readAll())
          }
          return
        }

        if (archive) {
          archive add(objectPath)
        }
    }

}

