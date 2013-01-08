
// sdk stuff
import io/File
import os/[Terminal, Process, JobPool]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, Archive, SourceFolder, Flags

import rock/frontend/[BuildParams, Target]
import rock/frontend/compilers/AbstractCompiler
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

        for(sourceFolder in sourceFolders) {
            archive := sourceFolder archive

            if(params libcache) {
                // now build static libraries for all source folders
                if(params veryVerbose || params debugLibcache) "Saving to library %s\n" printfln(sourceFolder outlib)
                archive save(params)
            }
        }

        if(params link && (params staticlib == null || params dynamiclib != null)) {

            initCompiler(params compiler)

            if(params linker != null) params compiler setExecutable(params linker)

            for(oPath in oPaths) {
                params compiler addObjectFile(oPath)
            }

            for(define in params defines) {
                params compiler defineSymbol(define)
            }

            for(dynamicLib in params dynamicLibs) {
                params compiler addDynamicLibrary(dynamicLib)
            }
            for(incPath in params incPath getPaths()) {
                params compiler addIncludePath(incPath getPath())
            }
            for(sourceFolder in sourceFolders) {
                if(params libcache) {
                    params compiler addIncludePath(params libcachePath + File separator + sourceFolder identifier)
                }
            }
            for(additional in params additionals) {
                params compiler addObjectFile(additional)
            }
            for(libPath in params libPath getPaths()) {
                params compiler addLibraryPath(libPath getAbsolutePath())
            }

            if(params binaryPath != "") {
                params compiler setOutputPath(params binaryPath)
            } else {
                checkBinaryNameCollision(module simpleName)
                params compiler setOutputPath(module simpleName)
            }

            flags := getFlagsFromUse(module)
            for(flag in flags) {
                params compiler addObjectFile(flag)
            }
            
            if(params enableGC) {
                if(params dynamiclib != null) {
                    params dynGC = true
                }
                if(params dynGC) {
                    params compiler addDynamicLibrary("gc")
                } else {
                    arch := params arch equals?("") ? Target getArch() : params arch
                    libPath := "libs/" + Target toString(arch) + "/libgc.a"
                    params compiler addObjectFile(File new(params distLocation, libPath) path)
                }
                params compiler addDynamicLibrary("pthread")
            }

            if(params verbose) params compiler getCommandLine() println()

            code := params compiler launch()
            if (code != 0) {
                return code
            }

        }

        if(params staticlib != null) {

            count := 0

            archive := Archive new("<staticlib>", params staticlib, params, false, null)
            if(params libfolder) {
                for(imp in module getGlobalImports()) {
                    archive add(imp getModule())
                    count += 1
                }
            } else {
                for(dep in module collectDeps()) {
                    archive add(dep)
                    count += 1
                }
            }

            if(params verbose) {
                "Building archive %s with %s (%d modules total)" printfln(
                    params staticlib,
                    params libfolder ? "modules belonging to %s" format(params libfolder) : "all object files",
                    count)
            }
            archive save(params)
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
                
                if(params packageFilter) {
                    dirtyModules = dirtyModules filter(|m|
                        m fullName startsWith?(params packageFilter)
                    )
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
            
            // apply libfolder and package filter to see if it belongs here
            if(params libfolder) {
                path1 := File new(params libfolder) getAbsolutePath()
                path2 := File new(module oocPath) getAbsolutePath()
                if(!path2 startsWith?(path1)) continue
            }
            if(params packageFilter && !module fullName startsWith?(params packageFilter)) {
                if(params verbose) "Filtering %s out" printfln(module fullName)
                continue
            }
            
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
    buildSourceFolder: func (sourceFolder: SourceFolder, objectFiles: List<String>, reGenerated: List<Module>) -> Int {

        if(params libfolder != null && sourceFolder absolutePath != File new(params libfolder) getAbsolutePath()) {
            if(params verbose) "Skipping (not needed for build of libfolder %s)" format(params libfolder) println()
            return 0
        }

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
    buildIndividual: func (module: Module, sourceFolder: SourceFolder, oPaths: List<String>, archive: Archive, force: Bool) -> Int {

        initCompiler(params compiler)
        params compiler setCompileOnly()

        path := File new(params outPath, module getPath("")) getPath()

        oPath := File new(params outPath, module path replaceAll(File separator, '_')) getPath() + ".o"
        cPath := path + ".c"
        if(oPaths) {
            oPaths add(oPath)
        }

        cFile := File new(cPath)
        oFile := File new(oPath)

        comparison := (archive ? File new(archive outlib) lastModified() : oFile lastModified())

        if(force || cFile lastModified() > comparison) {

            if(params veryVerbose || params debugLibcache) "%s not in cache or out of date, (re)compiling" printfln(module getFullName())

            parent := File new(oPath) parent()
            if(!parent exists?()) {
                if(params verbose) "Creating path %s" format(parent getPath()) println()
                parent mkdirs()
            }

            params compiler addObjectFile(cPath)
            params compiler setOutputPath(oPath)
            params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())

            if (params libcache) {
                params compiler addIncludePath(params libcachePath)
            } else {
                params compiler addIncludePath(params outPath getPath())
            }

            for(define in params defines) {
                params compiler defineSymbol(define)
            }
            for(dynamicLib in params dynamicLibs) {
                params compiler addDynamicLibrary(dynamicLib)
            }
            for(incPath in params incPath getPaths()) {
                params compiler addIncludePath(incPath getPath())
            }
            for(sourceFolder in sourceFolders) {
                params compiler addIncludePath(params libcachePath + File separator + sourceFolder identifier)
            }
            for(compilerArg in params compilerArgs) {
                params compiler addObjectFile(compilerArg)
            }

            flags := getFlagsFromUse(sourceFolder)
            for(flag in flags) {
                if (!isLinkerFlag(flag)) {
                    params compiler addObjectFile(flag)
                }
            }

            if(params verbose) params compiler getCommandLine() println()

            process := params compiler launchBackground()
            code := pool add(ModuleJob new(process, module, archive))
            if (code != 0) {
                // a process failed, can stop launching jobs now
                return code
            }


        } else {
            if(params veryVerbose || params debugLibcache) "Skipping %s, unchanged source.\n" printfln(cPath)
        }

        return 0

    }

    /**
       Get all the flags from uses in a source folder
     */
    getFlagsFromUse: func ~sourceFolder (sourceFolder: SourceFolder) -> List<String> {

        flagsDone := ArrayList<String> new()
        usesDone := ArrayList<UseDef> new()
        modulesDone := ArrayList<Module> new()

        for(module in sourceFolder modules) {
            getFlagsFromUse(module, flagsDone, modulesDone, usesDone)
        }


        flagsDone
    }

    initCompiler: func (compiler: AbstractCompiler) {
        compiler reset()

        if(params debug) params compiler setDebugEnabled()
        params compiler addIncludePath(File new(params distLocation, "libs/headers/") getPath())
        params compiler addIncludePath(params outPath getPath())

        for(compilerArg in params compilerArgs) {
            params compiler addObjectFile(compilerArg)
        }
    }

    /**
       Collect all modules imported from `module`, sort them by SourceFolder,
       put them in `toCompile`, and return it.
     */
    collectDeps: func (module: Module, toCompile: HashMap<String, SourceFolder>, done: ArrayList<Module>) -> HashMap<String, SourceFolder> {

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

