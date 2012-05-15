use libcee

import libcee/Parser
import structs/[ArrayList, List]
import rock/frontend/BuildParams
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

    init: func (=path, =mode, params: BuildParams) {
        defines = ArrayList<Define> new()

        if (params parseHeaders) {
            header = Header find(path)
            /*
            if (header) {
                "In %s" printfln(path)
                header symbols each(|k, v| k println())
            }
            */
        }
    }

}
