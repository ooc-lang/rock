
// sdk stuff
import io/File
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, Archive, SourceFolder, Flags, CCompiler

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, UseDef]
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

        params libcache = false

        // step 1: generate C sources
        for (sourceFolder in sourceFolders) {
            generateSources(sourceFolder)
        }

        1
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

}
