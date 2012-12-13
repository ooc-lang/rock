import io/[File, FileReader]
import structs/[List, ArrayList, HashMap]
import text/StringTokenizer

import ../frontend/BuildParams

/**
   Represents the requirement for a .use file, ie. a dependency
   The 'ver' string, if non-null/non-empty, should specify a minimal
   accepted version. But version checking of .use files isn't implemented
   in rock yet. (It may be supported by external tools such as reincarnate,
   though)

   :author: Amos Wenger (nddrylliog)
 */
Requirement: class {
    name, ver: String
    useDef: UseDef { get set }

    init: func (=name, =ver) {
    }
}

CustomPkg: class {
    utilName: String
    names := ArrayList<String> new()
    cflagArgs := ArrayList<String> new()
    libsArgs := ArrayList<String> new()

    init: func (=utilName)
}

/**
   Represents the data in a .use file, such as includes, include paths,
   libraries, packages (from pkg-config), requirements, etc.

   :author: Amos Wenger (nddrylliog)
 */
UseDef: class {
    cache := static HashMap<String, UseDef> new()

    identifier, name = "", description = "", version = "": String

    main : String = null
    file: File

    sourcePath : String = null

    linker : String = null

    requirements := ArrayList<Requirement> new()
    pkgs         := ArrayList<String> new()
    customPkgs   := ArrayList<CustomPkg> new()
    libs         := ArrayList<String> new()
    frameworks   := ArrayList<String> new()
    includes     := ArrayList<String> new()
    imports      := ArrayList<String> new()
    libPaths     := ArrayList<String> new()
    includePaths := ArrayList<String> new()

    init: func (=identifier) {}

    getRequirements: func -> List<Requirement> { requirements }
    getPkgs:         func -> List<String>      { pkgs }
    getCustomPkgs:   func -> List<CustomPkg>   { customPkgs }
    getLibs:         func -> List<String>      { libs }
    getFramework:    func -> List<String>      { frameworks }
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

            // parse requirements, if any
            for (req in cached requirements) {
                req useDef = This parse(req name, params)
            }
        }

        cached
    }

    findUse: static func (fileName: String, params: BuildParams) -> File {
        set := ArrayList<File> new()
        if(params libsPath exists?()) {
            set add(params libsPath)
        }
        set add(params sdkLocation)

        for(path in set) {
            if(path getPath() == null) continue

            for(subPath in path getChildren()) {
                if(subPath dir?() || subPath link?()) {
                    candidate := File new(subPath, fileName)
                    if(candidate exists?()) {
                        return candidate
                    }
                }
                if(subPath file?() || subPath link?()) {
                    if(subPath getPath() endsWith?(fileName)) {
                        return subPath
                    }
                }
            }
        }

        return null
    }

    apply: func (params: BuildParams) {
        if(!sourcePath) return

        sourcePathFile := File new(sourcePath)
        if(sourcePathFile relative?()) {
            /* is relative. TODO: better check? */
            sourcePathFile = file parent() getChild(sourcePath) getAbsoluteFile()
        }
        sourcePath = sourcePathFile path

        if(params veryVerbose) {
            "Adding %s to sourcepath ..." printfln(sourcePath)
        }
        params sourcePath add(sourcePath)

        if (linker) {
            params linker = linker
        }
    }

    parseCustomPkg: func (value: String) -> CustomPkg {
        vals := value split(',')
        pkg := CustomPkg new(vals[0])
        pkg names addAll(vals[1] trim() split(' '))
        if (vals size >= 4) {
            pkg cflagArgs addAll(vals[2] trim() split(' '))
            pkg libsArgs addAll(vals[3] trim() split(' '))
        } else {
            // If 3rd and 4th argument aren't present, assume pkgconfig-like behavior
            pkg cflagArgs add("--cflags")
            pkg libsArgs add("--libs")
        }
        pkg
    }

    read: func (=file, params: BuildParams) {
        reader := FileReader new(file)
        if(params veryVerbose) ("Reading use file " + file path) println()
        
        while(reader hasNext?()) {
            reader mark()
            c := reader read()
            if(params veryVerbose) "Got character %c" printfln(c)

            if(c == '\t' || c == ' ' || c == '\r' || c == '\n' || c == '\v') {
                continue
            }

            if(c == '#') {
                reader readUntil('\n')
                continue
            }

            if(c == '=') {
                // TODO: wasn't that used for platform-specific usefiles?
                reader skipLine()
                continue
            }

            reader rewind(1)
            id := reader readUntil(':')
            if(params veryVerbose) ("at first, id = '" + id + "'") println()
            
            id = id trim() trim(8 as Char /* backspace */) trim(0 as Char /* null-character */)
            
            value := reader readLine() trim()
            
            if(params veryVerbose) ("id = '" + id + "', value = '" + value + "'") println()

            if(id startsWith?("_")) {
                // reserved ids for external tools (packaging, etc.)
                continue
            }

            if(id == "Name") {
                name = value
            } else if(id == "Description") {
                description = value
            } else if(id == "Pkgs") {
                for(pkg in value split(','))
                    pkgs add(pkg trim())
            } else if(id == "CustomPkg") {
                customPkgs add(parseCustomPkg(value))
            } else if(id == "Libs") {
                for(lib in value split(','))
                    libs add(lib trim())
            } else if(id == "Frameworks") {
                for(framework in value split(','))
                    frameworks add(framework trim())
            } else if(id == "Includes") {
                for(inc in value split(','))
                    includes add(inc trim())
            } else if(id == "Linker") {
                linker = value trim()
            } else if(id == "LibPaths") {
                for(path in value split(',')) {
                    libFile := File new(path trim())
                    if(libFile relative?()) {
                        libFile = file parent() getChild(path) getAbsoluteFile()
                    }
                    libPaths add(libFile path)
                }
            } else if(id == "IncludePaths") {
                for(path in value split(',')) {
                    incFile := File new(path trim())
                    if(incFile relative?()) {
                        incFile = file parent() getChild(path) getAbsoluteFile()
                    }
                    includePaths add(incFile path)
                }
            } else if(id == "Requires") {
                for(req in value split(',')) {
                    // TODO: Version support!
                    requirements add(Requirement new(req trim(), "0"))
                }
            } else if(id == "SourcePath") {
                sourcePath = value
            } else if(id == "Version") {
                version = value
            } else if(id == "Imports") {
                for(imp in value split(','))
                    imports add(imp trim())
            } else if(id == "Origin" || id == "Variant") {
                // known, but ignored ids
            } else if(id == "Main") {
                main = value 
            } else if(id startsWith?("_")) {
                // unknown and ignored ids
            } else if(!id empty?()) {
                "Unknown key in %s: %s" format(file getPath(), id) println()
            }
        }
    }
}
