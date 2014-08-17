
// sdk stuff
import structs/[ArrayList, List]

// our stuff
import Version
import rock/frontend/Token
import rock/middle/tinker/[Resolver, Response, Trail, Errors]

IncludeMode: enum {
    LOCAL
    PATHY
    MACRO
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

    init: func (=token, =path, =mode) {
        detectMacro()
    }

    detectMacro: func {
        if (path startsWith?(".")) {
            path = path[1..-1]
            mode = IncludeMode MACRO
        }
    }

    setVersion: func(=verzion) {}
    getVersion: func -> VersionSpec { verzion }

    addDefine: func (define: Define) { defines add(define) }
    getDefines: func -> List<Define> { defines }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (verzion && !verzion isResolved()) {
            verzion resolve(trail, res)
        }
        Response OK
    }

    toString: func -> String {
        match mode {
            case IncludeMode LOCAL => "\"%s\""
            case IncludeMode PATHY => "<%s>"
        } format(path)
    }

}
