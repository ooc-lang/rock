
// sdk stuff
import structs/[ArrayList, List]

// our stuff
import Version
import rock/frontend/Token

IncludeMode: enum {
    LOCAL
    PATHY
}

Define: class {
    name, value: String

    init: func (=name, =value) {}
}

Include: class {

    token: Token
    path: String
    mode: IncludeMode
    verzion: VersionSpec
    defines := ArrayList<Define> new()

    init: func (=token, =path, =mode) {}

    setVersion: func(=verzion) {}
    getVersion: func -> VersionSpec { verzion }

    addDefine: func (define: Define) { defines add(define) }
    getDefines: func -> List<Define> { defines }

}
