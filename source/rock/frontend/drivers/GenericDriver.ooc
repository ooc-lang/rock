
// sdk stuff
import io/[File, FileWriter]
import structs/[List, ArrayList, HashMap]

// our stuff
import Driver, SequenceDriver, CCompiler, Flags, SourceFolder

import rock/frontend/[BuildParams, Target]
import rock/middle/[Module, UseDef]
import rock/backend/cnaughty/CGenerator
import rock/io/TabbedWriter

GenericDriver: class extends SequenceDriver {

    // the self-containing directory containing buildable C sources
    builddir: File

    // Our output file
    makefile: File
    filepath: String

    // Original output path (e.g. "rock_tmp")
    originalOutPath: File

    // The string name
    driverName: String

    getWriter: func (flags: Flags, toCompile: ArrayList<Module>, module: Module) -> GenericWriter { null }

    init: func(=filepath, =driverName, .params) { super(params) }

    setup: func {
        wasSetup := static false
        if(wasSetup) return

        // no lib-caching!
        params libcache = false

        // keeping them for later (ie. invocation)
        params clean = false

        // build/
        builddir = File new("build")

        // build/rock_tmp/
        originalOutPath = params outPath
        params outPath = File new(builddir, params outPath getPath())
        params outPath mkdirs()

        // the file to write
        makefile = File new(builddir, filepath)

        wasSetup = true
    }

    compile: func (module: Module) -> Int {

        if(params verbose) {
           driverName println()
        }

        setup()

        params outPath mkdirs()

        toCompile := ArrayList<Module> new()
        sourceFolders := collectDeps(module, HashMap<String, SourceFolder> new(), toCompile)

        for(candidate in toCompile) {
            CGenerator new(params, candidate) write()
        }

        params libcachePath = params outPath path
        copyLocals(module, params)

        params libcachePath = originalOutPath path
        params libcache = true
        flags := Flags new(null, params)

        // we'll do that ourselves
        flags doTargetSpecific = false

        // we'll handle the GC flags ourselves, thanks
        enableGC := params enableGC
        params enableGC = false
        flags absorb(params)
        params enableGC = enableGC

        for (sourceFolder in sourceFolders) {
            flags absorb(sourceFolder)
        }

        for (module in toCompile) {
            flags absorb(module)
        }
        params libcache = false

        // do the actual writing
        mw := getWriter(flags, toCompile, module)
        mw write()
        mw close()

        return 0

    }

}



GenericWriter: class {
    write: func
    close: func
}
