
// sdk stuff
import io/[File, FileWriter]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, Archive, SourceFolder, Flags, CCompiler

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, Use, UseDef]
import rock/backend/cnaughty/CGenerator

/**
 * Android NDK compilation driver - doesn't actually compile C files,
 * but prepares them in directories (one by SourceFolder) along with Android.mk
 * files for later compilation by ndk-build.
 *
 * In that case, ndk-build handles a lot of the work for us: dependencies,
 * partial recompilation, build flags - the Android.mk simili-Makefiles we
 * generate will be a lot shorter than the equivalent GNU Makefiles.
 *
 * :author: Amos Wenger (nddrylliog)
 */

AndroidDriver: class extends Driver {

    sourceFolders := HashMap<String, SourceFolder> new()

    init: func (.params) {
        super(params)
    }

    compile: func (module: Module) -> Int {
        "Android driver here, should compile module %s" printfln(module fullName)

        sourceFolders = collectDeps(module, HashMap<String, SourceFolder> new(), ArrayList<Module> new())

        // step 1: copy local headers
        params libcachePath = params outPath path
        copyLocals(module, params)

        // from the on, we handle the show - adjusting outPath as we go
        params libcache = false

        // step 2: generate C sources
        for (sourceFolder in sourceFolders) {
            generateSources(sourceFolder)
        }

        // step 3: generate Android.mk files
        for (sourceFolder in sourceFolders) {
            generateMakefile(sourceFolder)
        }

        0 
    }
    
    /**
     * Build a source folder into object files or a static library
     */
    generateSources: func (sourceFolder: SourceFolder) {

        originalOutPath := params outPath 
        params outPath = File new(originalOutPath, sourceFolder identifier)

        "Generating sources in %s" printfln(params outPath path)

        for(module in sourceFolder modules) {
            CGenerator new(params, module) write()
        }

        params outPath = originalOutPath

    }

    generateMakefile: func (sourceFolder: SourceFolder) {
        deps := collectSourceFolders(sourceFolder)
        uses := collectUses(sourceFolder)

        dest := File new(File new(params outPath, sourceFolder identifier), "Android.mk")
        fw := FileWriter new(dest)

        fw write("LOCAL_PATH := $(call my-dir)\n")
        fw write("\n")
        fw write("include $(CLEAR_VARS)\n")
        fw write("\n")
        fw write("LOCAL_MODULE := "). write(sourceFolder identifier). write("\n")
        fw write("LOCAL_C_INCLUDES := ")

        for (dep in deps) {
            fw write("$(LOCAL_PATH)/../"). write(dep identifier). write(" ")
        }
        fw write("$(LOCAL_PATH)/../"). write(sourceFolder identifier). write(" ")

        for (uze in uses) {
            for (path in uze androidIncludePaths) {
                fw write("$(LOCAL_PATH)/"). write(path). write(" ")
            }
        }

        fw write("\n")
        fw write("\n")

        fw write("LOCAL_SRC_FILES := ")
        for (module in sourceFolder modules) {
            path := module getPath(".c")
            fw write(path). write(" ")
        }

        uze := UseDef parse(sourceFolder identifier, params)
        if (uze) {
            for (additional in uze additionals) {
                cPath := File new(uze identifier, additional relative path) path

                if (params verbose) {
                    "cPath for additional: %s" printfln(cPath)
                }

                fw write(cPath). write(" ")
            }
        }
        fw write("\n")

        localSharedLibraries := ArrayList<String> new() 
        for (uze in uses) {
            localSharedLibraries addAll(uze androidLibs)
        }

        for (dep in deps) {
            localSharedLibraries add(dep identifier)
        }

        if (!localSharedLibraries empty?()) {
            fw write("LOCAL_SHARED_LIBRARIES := ")
            for (lib in localSharedLibraries) {
                fw write(lib). write(" ")
            }
            fw write("\n\n")
        }

        localLdLibs := ArrayList<String> new()
        for (uze in uses) {
            localLdLibs addAll(uze libs)
        }

        if (!localLdLibs empty?()) {
            fw write("LOCAL_LDLIBS := ")
            for (lib in localLdLibs) {
                fw write(lib). write(" ")
            }
            fw write("\n\n")
        }

        fw write("include $(BUILD_SHARED_LIBRARY)")

        fw close()
    }

    /** TODO: This is redundant with collectDeps, merge those */
    collectSourceFolders: func ~sourceFolders (sourceFolder: SourceFolder, \
            modulesDone := ArrayList<Module> new(), sourceFoldersDone := ArrayList<SourceFolder> new()) -> List<SourceFolder> {

        for (module in sourceFolder modules) {
            collectSourceFolders(module, modulesDone, sourceFoldersDone)
        }

        sourceFoldersDone filter(|sf| sf != sourceFolder)
    }

    collectSourceFolders: func ~modules (module: Module, \
            modulesDone := ArrayList<Module> new(), sourceFoldersDone := ArrayList<SourceFolder> new()) -> List<SourceFolder> {

        if (modulesDone contains?(module)) {
            return sourceFoldersDone
        }
        modulesDone add(module)
        
        for (uze in module getUses()) {
            useDef := uze useDef
            dep := sourceFolders get(useDef identifier)
            if (dep && !sourceFoldersDone contains?(dep)) {
                sourceFoldersDone add(dep)
            }
        }

        for (imp in module getAllImports()) {
            collectSourceFolders(imp getModule(), modulesDone, sourceFoldersDone)
        }

        sourceFoldersDone
    }

    doublePrefix: func -> Bool {
        true
    }

}
