
// sdk stuff
import io/[File, FileReader, StringReader]
import structs/[List, ArrayList, HashMap, Stack]
import text/StringTokenizer

// our stuff
import rock/frontend/[BuildParams, Target, Token]
import rock/frontend/drivers/AndroidDriver
import rock/middle/tinker/Errors

/**
 * Represents the requirement for a .use file, ie. a dependency
 * The 'ver' string, if non-null/non-empty, should specify a minimal
 * accepted version. But version checking of .use files isn't implemented
 * in rock yet. (It may be supported by external tools such as reincarnate,
 * though)
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
 * Represents the data in a .use file, such as includes, include paths,
 * libraries, packages (from pkg-config), requirements, etc.
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
    binarypath:    String { get set }
    luaBindings:   String { get set }

    imports             : ArrayList<String> { get set }
    preMains            : ArrayList<String> { get set }
    androidLibs         : ArrayList<String> { get set }
    androidIncludePaths : ArrayList<String> { get set }
    oocLibPaths         : ArrayList<File> { get set }
    requirements        : ArrayList<Requirement> { get set }

    properties := ArrayList<UseProperties> new()
    versionStack := Stack<UseProperties> new()

    // cache relevant properties
    _relevantProperties: UseProperties

    init: func (=identifier) {
        imports             = ArrayList<String> new()
        preMains            = ArrayList<String> new()
        androidLibs         = ArrayList<String> new()
        androidIncludePaths = ArrayList<String> new()
        oocLibPaths         = ArrayList<File> new()
        requirements        = ArrayList<Requirement> new()
    }

    parse: static func (identifier: String, params: BuildParams) -> UseDef {
        cached := This cache get(identifier)
        if(!cached) {
            cached = UseDef new(identifier)
            file := findUse(identifier + ".use", params)
            if(!file) return null

            if (params verboser) {
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

        for(path in set) {
            if(path getPath() == null) continue

            children := path getChildren()

            for(subPath in children) {
                if(subPath dir?() || subPath link?()) {
                    candidate := File new(subPath, fileName)
                    if(candidate exists?()) {
                        return candidate
                    }
                }
                if(subPath file?() || subPath link?()) {
                    if(subPath name == fileName) {
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
            sourcePathFile = file parent getChild(sourcePath) getAbsoluteFile()
        }
        sourcePath = sourcePathFile path

        params sourcePathTable put(sourcePath, this)
        params sourcePath add(sourcePath)

        if (linker) {
            params linker = linker
        }

        if (binarypath) {
            params binaryPath = binarypath
        }

        for (path in oocLibPaths) {
            params libsPaths add(path)
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

    parseVersionExpr: func (expr: String, params: BuildParams) -> UseVersion {
        reader := StringReader new(expr)
        not := false

        if (reader peek() == '!') {
            reader read()
            not = true
        }

        result: UseVersion

        if (reader peek() == '(') {
            reader read()
            level := 1

            buff := Buffer new()
            while (reader hasNext?()) {
                c := reader read()
                match c {
                    case '(' =>
                        level += 1
                        buff append(c)
                    case ')' =>
                        level -= 1
                        if (level == 0) {
                            break
                        }
                        buff append(c)
                    case =>
                        buff append(c)
                }
            }

            inner := buff toString()
            result = parseVersionExpr(inner, params)
        } else {
            // read an identifier
            value := reader readWhile(|c| c alphaNumeric?())
            result = UseVersionValue new(this, value)
        }

        if (not) {
            result = UseVersionNot new(this, result)
        }

        // skip whitespace
        reader skipWhile(|c| c whitespace?())

        if (reader hasNext?()) {
            c := reader read()
            match c {
                case '&' =>
                    // skip the second one
                    reader read()
                    reader skipWhile(|c| c whitespace?())

                    inner := parseVersionExpr(reader readAll(), params)
                    result = UseVersionAnd new(this, result, inner)
                case '|' =>
                    // skip the second one
                    reader read()
                    reader skipWhile(|c| c whitespace?())

                    inner := parseVersionExpr(reader readAll(), params)
                    result = UseVersionOr new(this, result, inner)
                case =>
                    message := "Malformed version expression: %s. Unexpected char %c" format(expr, c)
                    params errorHandler onError(UseFormatError new(this, message))
            }
        }

        result
    }

    read: func (=file, params: BuildParams) {
        reader := FileReader new(file)

        versionStack push(UseProperties new(this, UseVersion new(this)))

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
                lineReader rewind(1)
                versionExpr := lineReader readAll()[0..-2] trim()

                useVersion := parseVersionExpr(versionExpr, params)
                versionStack push(UseProperties new(this, useVersion))
                continue
            }

            if (line startsWith?("}")) {
                child := versionStack pop()
                parent := versionStack peek()

                child useVersion = UseVersionAnd new(this, parent useVersion, child useVersion)
                properties add(child)
                continue
            }

            id := lineReader readUntil(':')
            value := lineReader readAll() trim()

            if (id startsWith?("_")) {
                // reserved ids for external tools (packaging, etc.)
                continue
            }

            current := versionStack peek()

            if (id == "Name") {
                name = value
            } else if (id == "Description") {
                description = value
            } else if (id == "Pkgs") {
                for (pkg in value split(',')) {
                    current pkgs add(pkg trim())
                }
            } else if (id == "CustomPkg") {
                current customPkgs add(parseCustomPkg(value))
            } else if (id == "Libs") {
                for (lib in value split(',')) {
                    current libs add(lib trim())
                }
            } else if (id == "Frameworks") {
                for (framework in value split(',')) {
                    current frameworks add(framework trim())
                }
            } else if (id == "Includes") {
                for (inc in value split(',')) {
                    current includes add(inc trim())
                }
            } else if (id == "PreMains") {
                for (pm in value split(',')) {
                    preMains add(pm trim())
                }
            } else if (id == "Linker") {
                linker = value trim()
            } else if (id == "BinaryPath") {
                binarypath = value trim()
            } else if (id == "LibPaths") {
                for (path in value split(',')) {
                    libFile := File new(path trim())
                    if (libFile relative?()) {
                        libFile = file parent getChild(path) getAbsoluteFile()
                    }
                    current libPaths add(libFile path)
                }
            } else if (id == "IncludePaths") {
                for (path in value split(',')) {
                    incFile := File new(path trim())
                    if (incFile relative?()) {
                        incFile = file parent getChild(path) getAbsoluteFile()
                    }
                    current includePaths add(incFile path)
                }
            } else if (id == "AndroidLibs") {
                for (path in value split(',')) {
                    androidLibs add(path trim())
                }
            } else if (id == "AndroidIncludePaths") {
                for (path in value split(',')) {
                    androidIncludePaths add(path trim())
                }
            } else if (id == "OocLibPaths") {
                for (path in value split(',')) {
                    relative := File new(path trim()) getReducedFile()

                    if (!relative relative?()) {
                        "[WARNING]: ooc lib path %s is absolute - it's been ignored" printfln(relative path)
                        continue
                    }

                    candidate := file parent getChild(relative path)

                    absolute := match (candidate exists?()) {
                        case true =>
                            candidate getAbsoluteFile()
                        case =>
                            relative
                    }

                    oocLibPaths add(absolute)
                }
            } else if (id == "Additionals") {
                for (path in value split(',')) {
                    relative := File new(path trim()) getReducedFile()

                    if (!relative relative?()) {
                        "[WARNING]: Additional path %s is absolute - it's been ignored" printfln(relative path)
                        continue
                    }

                    candidate := file parent getChild(relative path)

                    absolute := match (candidate exists?()) {
                        case true =>
                            candidate getAbsoluteFile()
                        case =>
                            relative
                    }
                    current additionals add(Additional new(relative, absolute))
                }
            } else if (id == "Requires") {
                for (req in value split(',')) {
                    requirements add(Requirement new(req trim(), "0"))
                }
            } else if (id == "SourcePath") {
                if (sourcePath) {
                    "Duplicate SourcePath entry"
                } else {
                    sourcePath = value
                }
            } else if (id == "Version") {
                versionNumber = value
            } else if (id == "Imports") {
                for (imp in value split(',')) {
                    imports add(imp trim())
                }
            } else if (id == "Origin" || id == "Variant") {
                // known, but ignored ids
            } else if (id == "Main") {
                main = value
                if (!main endsWith?(".ooc")) {
                    main = "%s.ooc" format(main)
                }
            } else if (id == "LuaBindings") {
                luaBindings = value
            } else if (!id empty?()) {
                "Unknown key in %s: %s" format(file getPath(), id) println()
            }
        }

        reader close()
        properties add(versionStack pop())
    }

    getRelevantProperties: func (params: BuildParams) -> UseProperties {
        if (!_relevantProperties) {
            _relevantProperties = UseProperties new(this, UseVersion new(this))

            properties filter(|p| p useVersion satisfied?(params)) each(|p|
                _relevantProperties merge!(p)
            )
        }

        _relevantProperties
    }

    getPropertiesForTarget: func ~forTarget (target: Int) -> UseProperties {
        _relevantProperties = UseProperties new(this, UseVersion new(this))
        params := BuildParams new()
        params target = target
        properties filter(|p| p useVersion satisfied?(params)) each(|p|
            _relevantProperties merge!(p)
        )

        _relevantProperties
    }
}

UseProperties: class {
    useDef: UseDef
    useVersion: UseVersion { get set }

    pkgs                : ArrayList<String> { get set }
    customPkgs          : ArrayList<CustomPkg> { get set }
    additionals         : ArrayList<Additional> { get set }
    frameworks          : ArrayList<String> { get set }
    includePaths        : ArrayList<String> { get set }
    includes            : ArrayList<String> { get set }
    libPaths            : ArrayList<String> { get set }
    libs                : ArrayList<String> { get set }

    init: func (=useDef, =useVersion) {
        pkgs                = ArrayList<String> new()
        customPkgs          = ArrayList<CustomPkg> new()
        additionals         = ArrayList<Additional> new()
        frameworks          = ArrayList<String> new()
        includePaths        = ArrayList<String> new()
        includes            = ArrayList<String> new()
        libPaths            = ArrayList<String> new()
        libs                = ArrayList<String> new()
    }

    merge!: func (other: This) -> This {
        pkgs                      addAll(other pkgs)
        customPkgs                addAll(other customPkgs)
        additionals               addAll(other additionals)
        frameworks                addAll(other frameworks)
        includePaths              addAll(other includePaths)
        includes                  addAll(other includes)
        libPaths                  addAll(other libPaths)
        libs                      addAll(other libs)
    }
}

/**
 * Versioned block in a use def file
 *
 * This one is always satisfied
 */
UseVersion: class {
    useDef: UseDef

    init: func (=useDef)

    satisfied?: func (params: BuildParams) -> Bool {
        true
    }

    toString: func -> String {
        "true"
    }

    _: String { get { toString() } }
}

UseVersionValue: class extends UseVersion {
    value: String

    init: func (.useDef, =value) {
        super(useDef)
    }

    satisfied?: func (params: BuildParams) -> Bool {
        match value {
            case "linux" =>
                params target == Target LINUX
            case "windows" =>
                params target == Target WIN
            case "solaris" =>
                params target == Target SOLARIS
            case "haiku" =>
                params target == Target HAIKU
            case "apple" =>
                params target == Target OSX
            case "freebsd" =>
                params target == Target FREEBSD
            case "openbsd" =>
                params target == Target OPENBSD
            case "netbsd" =>
                params target == Target NETBSD
            case "dragonfly" =>
                params target == Target DRAGONFLY
            case "android" =>
                params driver instanceOf?(AndroidDriver)
            case "ios" =>
                // ios version not supported yet, false by default
                false
            case =>
                message := "Unknown version %s" format(value)
                params errorHandler onError(UseFormatError new(useDef, message))
                false
        }
    }

    toString: func -> String {
        "%s" format(value)
    }
}

UseVersionAnd: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useDef, =lhs, =rhs) {
        super(useDef)
    }

    satisfied?: func (params: BuildParams) -> Bool {
        lhs satisfied?(params) && rhs satisfied?(params)
    }

    toString: func -> String {
        "(%s && %s)" format(lhs _, rhs _)
    }
}

UseVersionOr: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useDef, =lhs, =rhs) {
        super(useDef)
    }

    satisfied?: func (params: BuildParams) -> Bool {
        lhs satisfied?(params) || rhs satisfied?(params)
    }

    toString: func -> String {
        "(%s || %s)" format(lhs _, rhs _)
    }
}

UseVersionNot: class extends UseVersion {
    inner: UseVersion

    init: func (.useDef, =inner) {
        super(useDef)
    }

    satisfied?: func (params: BuildParams) -> Bool {
        !inner satisfied?(params)
    }

    toString: func -> String {
        "!(%s)" format(inner _)
    }
}

UseFormatError: class extends Error {
    useDef: UseDef

    init: func (=useDef, .message) {
        super(nullToken, "Error while parsing %s: %s" format(useDef file path, message))
    }
}


