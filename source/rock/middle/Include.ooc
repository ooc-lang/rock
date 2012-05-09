import structs/[ArrayList, List]
import rock/parser/HeaderParser
import Version

IncludeMode: enum {
    QUOTED
    BRACKETED
}

Define: class {
    name, value: String

    init: func (=name, =value) {}
}

Include: class {

    path: String
    mode: IncludeMode
    verzion: VersionSpec { get set }
    defines: ArrayList<Define> { get set }

    header: Header { get set }

    init: func (=path, =mode) {
        defines = ArrayList<Define> new()

        header = Header find(path)
        if (header) {
            "In %s" printfln(path)
            header symbols each(|k, v| k println())
        }
    }

}
