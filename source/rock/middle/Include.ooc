import structs/[ArrayList, List]
import rock/parser/HeaderParser
import Version

IncludeMode: cover from Int

IncludeModes: class {
    LOCAL = 1,
    PATHY = 2 : static const IncludeMode
}

Define: class {
    name, value: String

    init: func (=name, =value) {}
}

Include: class {

    path: String
    mode: IncludeMode
    verzion: VersionSpec
    defines := ArrayList<Define> new()

    header: Header { get set }

    init: func (=path, =mode) {
        header = Header find(path)
        if (header) {
            "In %s" printfln(path)
            header symbols each(|k, v| k println())
        }
    }

    setVersion: func(=verzion) {}
    getVersion: func -> VersionSpec { verzion }

    addDefine: func (define: Define) { defines add(define) }
    getDefines: func -> List<Define> { defines }

}
