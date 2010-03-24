import io/File
import structs/[List, ArrayList, HashMap]
import text/StringTokenizer

import rock/frontend/[BuildParams, SourceReader]

Requirement: class {
    name, ver: String
    useDef: UseDef

    init: func (=name, =ver) {}
    
    getUseDef: func -> UseDef { useDef }
}

UseDef: class {
    cache := static HashMap<String, UseDef> new()
    
    identifier, name = "", description = "": String
    
    requirements := ArrayList<Requirement> new()
    pkgs         := ArrayList<String> new()
    libs         := ArrayList<String> new()
    includes     := ArrayList<String> new()
    libPaths     := ArrayList<String> new()
    includePaths := ArrayList<String> new()

    init: func (=identifier) {}
    
    getRequirements: func -> List<Requirement> { requirements }
    getPkgs:         func -> List<String>      { pkgs }
    getLibs:         func -> List<String>      { libs }
    getIncludes:     func -> List<String>      { includes }
    getLibPaths:     func -> List<String>      { libPaths }
    getIncludePaths: func -> List<String>      { includePaths }

    parse: static func (identifier: String, params: BuildParams) -> UseDef {
        cached := This cache get(identifier)
        if(!cached) {
            cached = UseDef new(identifier)
            file := findUse(identifier + ".use", params)
            if(!file) return null
            cached read(file, params)
            This cache put(identifier, cached)
        }
        
        cached
    }
    
    findUse: static func (fileName: String, params: BuildParams) -> File {
        set := ArrayList<File> new()
        set add(params libsPath)
        set add(params sdkLocation)
        
        while(!set isEmpty()) {
            nextSet := ArrayList<File> new()
            for(candidate in set) {
                if(candidate getPath() endsWith(fileName)) {
                    return candidate
                } else if(candidate isDir()) {
                    for(child in candidate getChildren()) {
                        nextSet add(child getAbsoluteFile())
                    }
                }
            }
            set = nextSet
        }
        
		return null
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
            value := reader readLine() trim() trim('\n')
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
                if(sourcePathFile isRelative()) {
                    /* is relative. TODO: better check? */
                    sourcePathFile = file parent() getChild(value) getAbsoluteFile()
                }
                if(params veryVerbose) "Adding %s to sourcepath ..." format(sourcePathFile path) println()
                params sourcePath add(sourcePathFile path)
            }
            reader hasWhitespace(true)
        }
    }
}
