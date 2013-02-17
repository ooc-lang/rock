
// sdk stuff
import structs/[ArrayList, HashMap]
import io/[File]

// our stuff
import rock/frontend/[BuildParams]
import rock/frontend/drivers/[SourceFolder]
import rock/middle/[Module, UseDef]
import rock/middle/tinker/[Errors]

/**
 * The dependency graph of a project, ie know the dependencies
 * between SourceFolder(s)
 * 
 * Used when figuring out what to build first
 *
 * :author: Amos Wenger
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
            message := "Orphan module: %s" format(module fullName)
            params errorHandler onError(InternalError new(module token, message))
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

    _computeList: func {
        // TODO: non-dumb algorithm
        "List of all dependencies: " println()
        deps each(|dep|
            dep _ println()
        )

        list = ArrayList<SourceFolder> new()
        sourceFolders each(|k, sf|
            list add(sf)
        )
    }

    _computeListExp: func {
        // start with all dependencies
        remaining := HashMap<String, Dependency> new()
        deps each(|k, v| remaining put(k, v))

        while (!remaining empty?()) {
            candidate: SourceFolder

            remaining each(|k, v|
                 
            )
        }
    }

}

/**
 * A dependency, ie. lhs => (needs) rhs to be built
 *
 * :author: Amos Wenger
 */
Dependency: class {

    lhs, rhs: SourceFolder

    init: func (=lhs, =rhs) {
    }

    toString: func -> String {
        "%s => %s" format(lhs identifier, rhs identifier)
    }

    _: String {
        get { toString() }
    }

}

