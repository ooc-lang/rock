
// sdk stuff
import io/File
import structs/[List, ArrayList]

// our stuff
import Driver

import rock/frontend/[BuildParams, Target]
import rock/middle/Module
import rock/backend/cnaughty/CGenerator

/**
 * Dummy driver, which only generates the .c source code
 *
 * Use it with -onlygen or -driver=dummy
 */
DummyDriver: class extends Driver {

    init: func (.params) {
        super(params)

        // Generating the sources is the *whole point* of onlygen.
        params clean = false

        // Don't do lib-caching, we don't want things in .libs/
        params libcache = false
    }

    compile: func (module: Module) -> Int {

        params outPath mkdirs()
        for(candidate in module collectDeps()) {
            CGenerator new(params, candidate) write()
        }

        copyLocals(module, params)

        if (params verbose) {
            "Generated sources in %s, enjoy!" format(params outPath path) println()
        }

        0

    }

}
