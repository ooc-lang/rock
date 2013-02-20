
// sdk stuff
import io/[File, FileReader, StringReader]
import structs/[List, ArrayList, HashMap, Stack]
import text/StringTokenizer

// our stuff
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
 * An additional is a .c / .s file that you want to add
 * to your ooc project to be compiled in.
 */
Additional: class {
    relative: File { get set }
    absolute: File { get set }

    init: func (=relative, =absolute) {
    }
}

/**
   Represents the data in a .use file, such as includes, include paths,
   libraries, packages (from pkg-config), requirements, etc.

   :author: Amos Wenger (nddrylliog)
 */
UseDef: class {
    cache := static HashMap<String, UseDef> new()

    file: File

    identifier:    String { get set }
    name:          String { get set }
    description:   String { get set }
    versionNumber: String { get set }
    sourcePath:    String { get set }
    linker:        String { get set }
    main:          String { get set }

    requirements        : ArrayList<Requirement> { get set }
    pkgs                : ArrayList<String> { get set }
    customPkgs          : ArrayList<CustomPkg> { get set }
    libs                : ArrayList<String> { get set }
    frameworks          : ArrayList<String> { get set }
    includes            : ArrayList<String> { get set }
    imports             : ArrayList<String> { get set }
    libPaths            : ArrayList<String> { get set }
    includePaths        : ArrayList<String> { get set }
    preMains            : ArrayList<String> { get set }
    androidLibs         : ArrayList<String> { get set }
    androidIncludePaths : ArrayList<String> { get set }

    versionBlocks := ArrayList<UseVersion> new()
    stack := Stack<UseVersion> new()

    init: func (=identifier) {
        requirements        = ArrayList<Requirement> new()
        pkgs                = ArrayList<String> new()
        customPkgs          = ArrayList<CustomPkg> new()
        libs                = ArrayList<String> new()
        frameworks          = ArrayList<String> new()
        includes            = ArrayList<String> new()
        imports             = ArrayList<String> new()
        libPaths            = ArrayList<String> new()
        includePaths        = ArrayList<String> new()
        preMains            = ArrayList<String> new()
        androidLibs         = ArrayList<String> new()
        androidIncludePaths = ArrayList<String> new()
    }

    parse: static func (identifier: String, params: BuildParams) -> UseDef {
        cached := This cache get(identifier)
        if(!cached) {
            cached = UseDef new(identifier)
            file := findUse(identifier + ".use", params)
            if(!file) return null

            if (params verbose) {
                "Use %s sourced from %s" printfln(identifier, file path)
            }

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
        set := params libsPaths

        if (params veryVerbose) {
            "ooc libs search path: " println()
            for (f in set) {
                " - %s" printfln(f getPath())
            }
        }

        for(path in set) {
            if(path getPath() == null) continue

            children := path getChildren()
            if (params veryVerbose) {
                "path %s has %d children" printfln(path getPath(), children size)
            }

            for(subPath in children) {
                if (params veryVerbose) {
                    "for subPath %s - dir %d - link %d file %d" printfln(subPath getPath(), \
                        subPath dir?(), subPath link?(), subPath file?())
                }
                if(subPath dir?() || subPath link?()) {
                    candidate := File new(subPath, fileName)
                    if (params veryVerbose) {
                        "testing candidate %s. exists? %d" printfln(candidate getPath(), candidate exists?())
                    }
                    if(candidate exists?()) {
                        return candidate
                    }
                }
                if(subPath file?() || subPath link?()) {
                    if (params veryVerbose) {
                        candidate := File new(subPath, fileName)
                    }
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
            sourcePathFile = file parent getChild(sourcePath) getAbsoluteFile()
        }
        sourcePath = sourcePathFile path

        if(params veryVerbose) {
            "Adding %s to sourcepath ..." printfln(sourcePath)
        }
        params sourcePathTable put(sourcePath, this)
        params sourcePath add(sourcePath)

        if (linker) {
            params linker = linker
        }
    }

    parseCustomPkg: func (value: String) -> CustomPkg {
        vals := value split(',')
        pkg := CustomPkg new(vals[0])

        if (vals size >= 2) {
            pkg names addAll(vals[1] trim() split(' ', false))
        }

        if (vals size >= 4) {
            pkg cflagArgs addAll(vals[2] trim() split(' ', false))
            pkg libsArgs addAll(vals[3] trim() split(' ', false))
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

        stack push(UseVersion new())
        
        while(reader hasNext?()) {
            line := reader readLine() \
                           trim() /* general whitespace */ \
                           trim(8 as Char /* backspace */) \
                           trim(0 as Char /* null byte */)

            if (line empty?() || line startsWith?('#')) {
                // skip comments
                continue
            }

            lineReader := StringReader new(line)
            if (line startsWith?("version")) {
                lineReader readUntil('(')
                versionExpr := lineReader readUntil(')')
                "Got version expression: %s" printfln(versionExpr)
                continue
            }

            if (line startsWith?("}")) {
                "Version expression closed" println()
                continue
            }

            id := lineReader readUntil(':')
            value := lineReader readAll() trim()
            
            if (id startsWith?("_")) {
                // reserved ids for external tools (packaging, etc.)
                continue
            }

            if (id == "Name") {
                name = value
            } else if (id == "Description") {
                description = value
            } else if (id == "Pkgs") {
                for (pkg in value split(','))
                    pkgs add(pkg trim())
            } else if (id == "CustomPkg") {
                customPkgs add(parseCustomPkg(value))
            } else if (id == "Libs") {
                for (lib in value split(','))
                    libs add(lib trim())
            } else if (id == "Frameworks") {
                for (framework in value split(','))
                    frameworks add(framework trim())
            } else if (id == "Includes") {
                for (inc in value split(','))
                    includes add(inc trim())
            } else if (id == "PreMains") {
                for (pm in value split(','))
                    preMains add(pm trim())
            } else if (id == "Linker") {
                linker = value trim()
            } else if (id == "LibPaths") {
                for (path in value split(',')) {
                    libFile := File new(path trim())
                    if (libFile relative?()) {
                        libFile = file parent getChild(path) getAbsoluteFile()
                    }
                    libPaths add(libFile path)
                }
            } else if (id == "IncludePaths") {
                for (path in value split(',')) {
                    incFile := File new(path trim())
                    if (incFile relative?()) {
                        incFile = file parent getChild(path) getAbsoluteFile()
                    }
                    includePaths add(incFile path)
                }
            } else if (id == "AndroidLibs") {
                for (path in value split(',')) {
                    androidLibs add(path trim())
                }
            } else if (id == "AndroidIncludePaths") {
                for (path in value split(',')) {
                    androidIncludePaths add(path trim())
                }
            } else if (id == "Additionals") {
                for (path in value split(',')) {
                    relative := File new(path trim()) getReducedFile()
                    absolute := file parent getChild(relative path) getAbsoluteFile()

                    if (!relative relative?()) {
                        "[WARNING]: Additional path %s is absolute - it's been ignored" printfln(relative path)
                        continue
                    }

                    if (params verbose) {
                        "relative path: %s / %d" printfln(relative path, relative exists?())
                        "absolute path: %s / %d" printfln(absolute path, absolute exists?())
                    }
                    stack peek() properties additionals add(Additional new(relative, absolute))
                }
            } else if (id == "Requires") {
                for (req in value split(',')) {
                    // TODO: Version support!
                    requirements add(Requirement new(req trim(), "0"))
                }
            } else if (id == "SourcePath") {
                sourcePath = value
            } else if (id == "Version") {
                versionNumber = value
            } else if (id == "Imports") {
                for (imp in value split(','))
                    imports add(imp trim())
            } else if (id == "Origin" || id == "Variant") {
                // known, but ignored ids
            } else if (id == "Main") {
                main = value 
            } else if (id startsWith?("_")) {
                // unknown and ignored ids
            } else if (!id empty?()) {
                "Unknown key in %s: %s" format(file getPath(), id) println()
            }
        }

        reader close()
        versionBlocks add(stack pop())
    }

    getRelevantProperties: func (params: BuildParams) -> UseProperties {
        result := UseProperties new()

        versionBlocks filter(|vb| vb satisfied?(params)) each(|vb|
            result merge!(vb properties)
        )
        result
    }
}

UseProperties: class {
    additionals         : ArrayList<Additional> { get set }

    init: func {
        additionals         = ArrayList<Additional> new()
    }

    merge!: func (other: This) -> This {
        additionals addAll(other additionals)
    }
}

/**
 * Versioned block in a use def file
 *
 * This one is always satisfied
 */
UseVersion: class {
    properties: UseProperties { get set }

    init: func {
        properties = UseProperties new()
    }

    satisfied?: func (params: BuildParams) -> Bool {
        true
    }
}

