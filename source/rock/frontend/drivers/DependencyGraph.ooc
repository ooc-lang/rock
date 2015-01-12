
// sdk stuff
import structs/[ArrayList, HashMap]
import io/[File]

// our stuff
import rock/frontend/[BuildParams, Token]
import rock/frontend/drivers/[SourceFolder]
import rock/middle/[Module, UseDef]
import rock/middle/tinker/[Errors]

/**
 * The dependency graph of a project, ie know the dependencies
 * between SourceFolder(s)
 *
 * Used when figuring out what to build first
 */
DependencyGraph: class {

    params: BuildParams

    sourceFolders := HashMap<String, SourceFolder> new()
    deps := HashMap<String, Dependency> new()

    list: ArrayList<SourceFolder> { get set }

    init: func (=params, =sourceFolders) {
        // add all dependencies from root

        sourceFolders each(|sf|
            _walk(sf)
        )

        _computeList()
    }

    _throwError: func (token: Token, message: String) {
        params errorHandler onError(DependencyError new(token, message))
    }

    _walk: func (parent: SourceFolder) {
        done := ArrayList<Module> new()

        for (module in parent modules) {
            _walk(parent, module, done)
        }
    }

    _walk: func ~module (parent: SourceFolder, module: Module, done: ArrayList<Module>) {
        if (done contains?(module)) return
        done add(module)

        pathElement := module getPathElement()
        absolutePath := File new(pathElement) getAbsolutePath()
        name := File new(absolutePath) name

        uze := params sourcePathTable get(pathElement)
        identifier := uze ? uze identifier : name

        dep := sourceFolders get(identifier)
        if (!dep) {
            _throwError(module token, "Orphan module: %s" format(module fullName))
            return
        }

        if (parent != dep) {
            _addDependency(parent, dep)
        }

        for (import1 in module getAllImports()) {
            child := import1 getModule()
            if(done contains?(child)) continue
            _walk(dep, child, done)
        }
    }


    _addDependency: func (lhs, rhs: SourceFolder) {
        key := "%s => %s" format(lhs identifier, rhs identifier)

        if (!deps contains?(key)) {
            deps put(key, Dependency new(lhs, rhs))
        }
    }

    _numDependencies: func (sf: SourceFolder) -> Int {
        count := 0

        for (dep in deps) {
            if (!dep satisfied && dep lhs == sf) {
                count += 1
            }
        }

        count
    }

    _satisfyDependents: func (sf: SourceFolder) {
        for (dep in deps) {
            if (dep rhs == sf) {
                dep satisfy()
            }
        }
    }

    _computeList: func {
        pool := ArrayList<SourceFolder> new()
        sourceFolders each(|k, sf| pool add(sf))

        list = ArrayList<SourceFolder> new()

        while (!pool empty?()) {
            candidate: SourceFolder

            for (sf in pool) {
                if (_numDependencies(sf) == 0) {
                    candidate = sf
                    break
                }
            }

            if (candidate) {
                _satisfyDependents(candidate)
                pool remove(candidate)
                list add(0, candidate)
            } else {
                repr := pool map(|sf| sf identifier) join(", ")
                message := "Circular dependencies among remaining modules: [%s]" format(repr)

                if (params verbose) {
                    message += "\nDependency Graph: \n"
                    for(sf in pool){
                        message += "%s : %d [\n" \
                                format(sf identifier, _numDependencies(sf))
                        for (dep in deps) {
                            if (!dep satisfied && dep lhs == sf) {
                                message += "\t"+dep toString()+"\n"
                            }
                        }
                        message += "]\n"
                    }
                }

                _throwError(nullToken, message)
            }
        }

        if (params verboser) {
            repr := list map(|sf| sf identifier) join(", ")
            "Build order: [%s]" printfln(repr)
        }
    }

}

/**
 * A dependency, ie. lhs => (needs) rhs to be built
 */
Dependency: class {

    lhs, rhs: SourceFolder
    satisfied := false

    init: func (=lhs, =rhs) {
    }

    toString: func -> String {
        "%s => %s" format(lhs identifier, rhs identifier)
    }

    _: String {
        get { toString() }
    }

    satisfy: func {
        satisfied = true
    }

}

DependencyError: class extends Error {

    init: super func ~tokenMessage

}

