import io/File
import structs/ArrayList
import text/StringTokenizer

import rock/frontend/[BuildParams, SourceReader]

Requirement: class {
    name, ver: String
    useDef: UseDef

    init: func (=name, =ver) {
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

    read: func (file: File, params: BuildParams) {
        reader := SourceReader getReaderFromFile(file)
        while(reader hasNext()) {
            reader hasWhitespace(true)
            
            if(reader matches("#", false)) {
                reader skipLine()
                continue 
            }

            if(reader matches("=", false)) {
                reader skipLine()
                continue
            }

            id := reader readUntil(':', false) trim()
            reader read() // skip the ':'
            value := reader readLine() trim()
            if(id == "Name") {
                name = value
            } else if(id == "Description") {
                description = value
            } else if(id == "Pkgs") {
                for(pkg in value split(','))
                    pkgs add(pkg trim())
            } else if(id == "Libs") {
                for(lib in value split(','))
                    libs add(lib trim())
            } else if(id == "Includes") {
                for(inc in value split(','))
                    includes add(inc trim())
            } else if(id == "LibPaths") {
                for(path in value split(',')) {
                    libFile := File new(path trim())
                    if(libFile getAbsoluteFile() != libFile) {
                        /* is relative. TODO: better check? */
                        libFile = file getChild(path) getAbsoluteFile()
                    }
                    libPaths add(libFile path)
                }
            } else if(id == "IncludePaths") {
                for(path in value split(',')) {
                    incFile := File new(path trim())
                    if(incFile getAbsoluteFile() != incFile) {
                        /* is relative. TODO: better check? */
                        incFile = file getChild(path) getAbsoluteFile()
                    }
                    includePaths add(incFile path)
                }
            } else if(id == "Requires") {
                for(req in value split(',')) {
                    requirements add(Requirement new(req trim(), "0")) // TODO: Version support!
                }
            } else if(id == "SourcePath") {
                sourcePathFile := File new(value)
                if(sourcePathFile getAbsoluteFile() != sourcePathFile) {
                    /* is relative. TODO: better check? */
                    sourcePathFile = file getChild(value) getAbsoluteFile()
                }
                if(params verbose) {
                    "Adding %s to sourcepath ..." format(sourcePathFile path) println()
                }
                params sourcePath add(sourcePathFile path)
            }
            reader hasWhitespace(true)
        }
    }
}
