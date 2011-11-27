import io/[File], os/[Terminal, Process]
import structs/[List, ArrayList, HashMap]
import ../[BuildParams, Target]
import ../compilers/AbstractCompiler
import ../../middle/[Module, UseDef]
import ../../backend/cnaughty/CGenerator
import Driver, Archive

/**
   Sequence driver, which compiles .c files one by one as needed.

   With -noclean, the rock_tmp/ folder (or whatever your -outpath is set to)
   will not be deleted and the sequence driver will take advantage of that.

   But sequence driver allows partial recompilation even without the rock_tmp
   folder, thanks to lib-caching. By default, the result of the compilation is
   put into a .libs/ folder, cached by source-folder name, for example after
   a simple compilation you may end up with:

     - .libs/sdk-linux32.a
     - .libs/sdk-linux32.a.cacheinfo
     - .libs/helloworld-linux32.a
     - .libs/helloworld-linux32.a.cacheinfo

   The .a files are archives that contain the object files (.o) that result
   of the compilation of your program.

   When you recompile a program with an existing .libs/ directory,
   the SequenceDriver will use the .cacheinfo files to determine
   what needs to be re-compile, update the .a files with the new object
   files, and link again.

   However, there are times (for example, when you upgrade rock) where
   .libs/ can be harmful and prevent a program from compiling/running
   normally. If you experience any weird behavior, be sure to *remove it
   completely* and re-try with a clean compile before reporting issues.

   :author: Amos Wenger (nddrylliog)
 */
SequenceDriver: class extends Driver {

    sourceFolders: HashMap<String, SourceFolder>

    init: func (.params) { super(params) }

    compile: func (module: Module) -> Int {

        if(params verbose) {
            ("Sequence driver, using " + params sequenceThreads toString() + " thread" + (params sequenceThreads > 1 ? "s" : "")) println()
        }

        copyLocalHeaders(module, params, ArrayList<Module> new())

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())

        oPaths := ArrayList<String> new()
        reGenerated := HashMap<SourceFolder, List<Module>> new()

        for(sourceFolder in sourceFolders) {
            reGenerated put(sourceFolder, prepareSourceFolder(sourceFolder, oPaths))
        }

        for(sourceFolder in sourceFolders) {
            if(params verbose) {
                // generate random colors for every source folder
                hash := ac_X31_hash(sourceFolder name) + 42
                Terminal setFgColor((hash % (Color cyan - Color red)) + Color red)
                if(hash & 0b01) Terminal setAttr(Attr bright)
                "%s, " printf(sourceFolder name)
                Terminal reset()
                fflush(stdout)
            }
            code := buildSourceFolder(sourceFolder, oPaths, reGenerated get(sourceFolder))
            if(code != 0) return code
        }
        if(params verbose) println()

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
					params compiler addIncludePath(params libcachePath + File separator + sourceFolder name)
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

            libs := getFlagsFromUse(module)
            for(lib in libs) {
                params compiler addObjectFile(lib)
            }
            
            if(params enableGC) {
                params compiler addDynamicLibrary("pthread")
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
            }

            if(params verbose) params compiler getCommandLine() println()

            code := params compiler launch()

            if(code != 0) {
                fprintf(stderr, "C compiler failed (got code %d), aborting compilation process\n", code)
                return code
            }

        }

        if(params staticlib != null) {

            count := 0

            archive := Archive new("<staticlib>", params staticlib, params, false)
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
				oPath := File new(params outPath, module path replaceAll(File separator, '_')) getPath() + ".o"
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

            if(archive exists?) {
                if(reGenerated getSize() > 0) {
                    if(params verbose) printf("\n%d new/updated modules to compile\n", reGenerated getSize())
                    for(module in reGenerated) {
                        code := buildIndividual(module, sourceFolder, null, archive, true)
                        if(code != 0) return code
                    }

                    archive save(params)
                }
                return 0
            }
        }

        oPaths := ArrayList<String> new()

        if(params verbose) printf("Compiling regenerated modules...\n")
        //for(module in sourceFolder modules) {
		for(module in reGenerated) {
            code := buildIndividual(module, sourceFolder, oPaths, null, false)
            archive add(module)
            if(code != 0) return code
        }

        if(params libcache) {
            // now build a static library
            if(params veryVerbose || params debugLibcache) "Saving to library %s\n" printfln(sourceFolder outlib)
            archive save(params)
        } else {
            if(params veryVerbose || params debugLibcache) "Lib caching disabled, building from .o files\n" println()
         
            objectFiles addAll(oPaths)
        }

        return 0

    }

    /**
       Build an individual ooc files to its .o file, add it to oPaths
     */
    buildIndividual: func (module: Module, sourceFolder: SourceFolder, oPaths: List<String>, archive: Archive, force: Bool) -> Int {

        initCompiler(params compiler)
        params compiler setCompileOnly()

        path := File new(params outPath, module getPath("")) getPath()
        //printf("build individual called, outPath=%s module=%s path=%s\n", params outPath path, module getPath(""), path)

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
            params compiler addIncludePath(params outPath getPath())

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
                params compiler addIncludePath(params libcachePath + File separator + sourceFolder name)
            }
            for(compilerArg in params compilerArgs) {
                params compiler addObjectFile(compilerArg)
            }

            libs := getFlagsFromUse(sourceFolder)
            for(lib in libs) {
                params compiler addObjectFile(lib)
            }

            if(params verbose) params compiler getCommandLine() println()

            code := params compiler launch()

            if(code != 0) {
                fprintf(stderr, "C compiler failed (with code %d), aborting compilation process\n", code)
                return code
            }

            if(archive) archive add(module)

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

        for(module in sourceFolder modules) {
            for(use1 in module uses) {
                getFlagsFromUse(use1 useDef, flagsDone, usesDone)
            }
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
            absolutePath := File new(module getPathElement()) getAbsolutePath()
            name := File new(absolutePath) name()

            sourceFolder := toCompile get(name)
            if(sourceFolder == null) {
                sourceFolder = SourceFolder new(name, absolutePath, params)
                toCompile put(name, sourceFolder)
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

SourceFolder: class {
    name, absolutePath: String
    params: BuildParams
    outlib: String

    modules := ArrayList<Module> new()
    archive : Archive

    init: func (=name, =absolutePath, =params) {
        outlib = "%s%c%s-%s.a" format(params libcachePath, File separator, name, Target toString())
        archive = Archive new(name, outlib, params)
    }
}
