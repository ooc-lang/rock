import structs/ArrayList

Requirement: class {
    name, version: String
    useDef: UseDef

    init: func (=name, =version) {
    }
}

UseDef: class {
    identifier, name, description: String
    requirements: ArrayList<Requirement>
    pkgs, libs, includes, libPaths, includePaths: ArrayList<String>

    init: func (=identifier) {
        requirements = ArrayList<Requirement> new()
        name = ""
        description = ""
        pkgs = ArrayList<String> new()
        libs = ArrayList<String> new()
        includes = ArrayList<String> new()
        libPaths = ArrayList<String> new()
        includePaths = ArrayList<String> new()
    }
}
