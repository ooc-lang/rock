
// sdk stuff
import structs/[List, ArrayList, HashMap]
import io/[File, FileReader, FileWriter], os/[Process, Env]

// our stuff
import rock/RockVersion
import rock/frontend/[AstBuilder, BuildParams, PathList]
import rock/middle/[Module, TypeDecl, VariableDecl, FunctionDecl]
import rock/backend/cnaughty/ModuleWriter

/**
 * Manage .a files stored in .libs/, with their .a.cacheinfo
 * files, can check up-to-dateness, add files, etc.
 *
 * :author: Amos Wenger (nddrylliog)
 */
Archive: class {

    version := static "0.3"

    map := static HashMap<Module, Archive> new()

    /** Source folder that this archive is for */
    sourceFolder: String

    /** Location of the source-folder in the file system. */
    pathElement: File

    /** Path of the file where the archive is stored */
    outlib: String

    /** The build parameters */
    params: BuildParams

    /** A string representation of compiler options */
    compilerArgs: String

    /** Map of elements contained in the archive */
    elements := HashMap<String, ArchiveModule> new()

    /** List of modules contained in this archive */
    modules := ArrayList<Module> new()

    /** List of sub-archives contained in this archive */
    archives := ArrayList<Archive> new()

    /** Write .cacheinfo files or not */
    doCacheinfo := true

    /** Create a new Archive */
    init: func ~archiveCacheinfo (=sourceFolder, =outlib, =params, =doCacheinfo, =pathElement) {
        compilerArgs = params getArgsRepr()
        if(doCacheinfo) {
            if(File new(outlib) exists?() && File new(outlib + ".cacheinfo") exists?()) {
                _read()
            }
        }
    }

    _readHeader: func (fR: FileReader) -> Bool {
        cacheversion  := fR readLine()
        if(cacheversion != "cacheversion") {
            if(params veryVerbose || params debugLibcache) {
                "Malformed cacheinfo file %s.cacheinfo, ignoring." format(outlib) println()
            }
            return false
        }

        readVersion := fR readLine()
        if(readVersion != version) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong version %s for %s.cacheinfo. We only read version %s. Ignoring" format(readVersion, outlib, version) println()
            }
            return false
        }

        readCompilerArgs := fR readLine()
        if(readCompilerArgs != compilerArgs) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong compiler args '%s' for %s.cacheinfo. We have args '%s'. Ignoring" format(readCompilerArgs, outlib, compilerArgs) println()
            }
            return false
        }

        readCompilerVersion := fR readLine()
        if(readCompilerVersion != RockVersion getName()) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong compiler version '%s' for %s.cacheinfo. We have version '%s'. Ignoring" format(readCompilerVersion, outlib, RockVersion getName()) println()
            }
            return false
        }

        true
    }

    _read: func {
        fR := FileReader new(outlib + ".cacheinfo")

        if(!_readHeader(fR)) {
            fR close()
            return
        }

        cacheSize := fR readLine() toInt()

        for(i in 0..cacheSize) {
            element := ArchiveModule new(fR, this)
            if(element module == null) {
                // If the element' module is null, it means that there are files
                // in the cache that we don't need to compile for this run.
                // Typically, the compiler has been launched several times
                // in the same folder for different .ooc files

                // If it contains a main, then it *needs* to be removed
                // from the archive file, otherwise there would be two mains
                // and the resulting app would probably launch the wrong main..

                // For now, we remove it anyway - later, we might want to check
                // if it does really contain a main
                if(params veryVerbose || params debugLibcache) {
                    "Removing %s from archive %s" printfln(element oocPath, outlib)
                }

                // turn "blah/file.ooc" into "blah_file.o"
                name := element oocPath replaceAll(File separator, '_')

                args := ArrayList<String> new()
                args add("ar") .add((params veryVerbose || params debugLibcache) ? "dv" : "d"). add(outlib). add(name substring(0, name length() - 2))

                output := Process new(args) getOutput()

                if(params verbose || params debugLibcache) {
                    args join(" ") println()
                    output println()
                }
            } else {
                map put(element module, this)
                elements put(element oocPath, element)
            }
        }
        fR close()
    }

    _write: func {
        fW := FileWriter new(outlib + ".cacheinfo")

        fW writef("cacheversion\n%s\n", version)
        fW writef("%s\n", compilerArgs)
        fW writef("%s\n", RockVersion getName())
        fW writef("%d\n", elements getSize())
        for(element in elements) {
            element write(fW)
        }
        fW close()
    }

    /**
       Schedule the addition of a module to this archive.
       save() must be called afterwards so that bunches of
       modules can be added all at once.
     */
    add: func (module: Module) {
        modules add(module)
        map put(module, this)
    }

    add: func ~archive (archive: Archive) {
        archives add(archive)
    }

    /**
       true if the .a file storing this archive has already been
       written to disk once.
     */
    exists?: Bool {
        get {
            if(!File new(outlib) exists?()) return false
            if(!doCacheinfo) return false

            fR := FileReader new(outlib + ".cacheinfo")
            result := _readHeader(fR)
            fR close()
            return result
        }
    }

    dirtyModules: func (modules: List<Module>) -> List<Module> {

        dirtyModules := ArrayList<Module> new()
        structuralDirties := ArrayList<Module> new()
        transModules := ArrayList<Module> new()
        cleanModules := ArrayList<Module> new()
        cleanModules addAll(modules)

        dotOutput := (Env get("ROCK_DOT_OUTPUT") == "1")
        dotFile: FileWriter
        if(dotOutput) {
            params debugLibcache = true
            dotFile = FileWriter new("deps-" + sourceFolder + ".dot")
            dotFile write("digraph deps {\n")
            dotFile write("rankdir = LR;\n")
        }
        
        running := true
        while(running) {
            if(params veryVerbose || params debugLibcache) {
                "Analyzing %s, %d cleanModules, %d dirtyModules" printfln(pathElement path, cleanModules getSize(), dirtyModules getSize())
            }

            for(module in cleanModules) {
                subArchive := map get(module)
                if(!subArchive) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s is dirty because we can't find the archive" printfln(module getFullName())
                        if(dotOutput) {
                            dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("ArchiveNotFound;\n")
                        }
                    }
                    transModules add(module); continue
                }
                oocPath := module path + ".ooc"
                element := subArchive elements get(oocPath)
                if(!element) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s is dirty because we can't find the element in archive %s" format(module getFullName(), subArchive pathElement path) println()
                    }
                    if(dotOutput) {
                        dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("\"ElementNotInArchive\";\n")
                    }
                    transModules add(module); continue
                }
                if(!element upToDate?) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s is dirty because of element %s" printfln(module getFullName(), element oocPath)
                    }
                    if(dotOutput) {
                        dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("\"StructuralDirty\";\n")
                    }
                    subArchive elements put(oocPath, ArchiveModule new(module, subArchive))
                    structuralDirties add(module)
                    transModules add(module)
                    continue
                }

                oocFile := File new(subArchive pathElement, oocPath)
                lastModified := oocFile lastModified()
                if(lastModified != element lastModified) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s out-of-date, recompiling... (%d vs %d, oocPath = %s)" printfln(module getFullName(), lastModified, element lastModified, oocPath)
                    }
                    if(dotOutput) {
                        dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("\"OutOfDate\";\n")
                    }
                    transModules add(module); continue
                }

                trans := false
                for(imp in ModuleWriter classifyImports(null, module)) {
                    candidate := imp getModule()
                    if(structuralDirties contains?(candidate)) {
                        if(params veryVerbose || params debugLibcache) {
                            "%s is dirty because of import %s" format(module getFullName(), candidate getFullName()) println()
                        }
                        if(!trans) {
                            if(dotOutput) {
                                dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("\""). write(candidate simpleName). write("\";\n")
                            }
                            transModules add(module)
                            trans = true
                        }
                        if(imp isTight) {
                            structuralDirties add(module)
                            break // and we can stop searching
                        }
                    }
                }
            }

            if(transModules empty?()) {
                running = false
            } else {
                if(params veryVerbose || params debugLibcache) {
                    "[%s] We have %d transmodules to handle" format(pathElement path, transModules getSize()) println()
                }
                for (module in transModules) {
                    if(params veryVerbose || params debugLibcache) {
                        " - %s" format(module getFullName()) println()
                    }
                    dirtyModules add(module)
                    cleanModules remove(module)
                }
                transModules clear()
            }
        }

        if(dotOutput) {
            dotFile write("}\n"). close()
        }

        dirtyModules

    }

    /**
       Must be called after add calls to apply the changes
       to the archives.
     */
    save: func (params: BuildParams, symbolTable, thin: Bool) {
        // now build static libraries for all source folders
        if(params veryVerbose || params debugLibcache) {
            "Creating/updating archive %s\n" printfln(outlib)
        }

        if (modules empty?() && archives empty?()) {
            if(params veryVerbose || params debugLibcache) {
                "No (new?) member in archive %s, skipping" printfln(pathElement path)
            }
            return
        }

        args := ArrayList<String> new()
        args add("ar") // GNU ar tool, manages archives

        flags := ArrayList<String> new()

        if(!this exists?) {
            flags add("c") // create
        }

        flags add("r") // insert with replacement

        if (symbolTable) {
            flags add("s")
        }

        if (thin) {
            flags add("T")
        }

        if (params veryVerbose || params debugLibcache) {
            flags add("v") // verbose
        }

        args add(flags join(""))

        // output path
        args add(outlib)

        for (module in modules) {
            // we add .o (object files) to the archive
            oName := "%s.o" format(module path replaceAll(File separator, '_'))
            oPath := File new(params outPath, oName) getPath()
            args add(oPath)

            element := ArchiveModule new(module, this)
            elements put(element oocPath, element) // replace
        }

        for (archive in archives) {
            args add(archive outlib)
        }

        File new(outlib) parent mkdirs()
        process := Process new(args)

        if(params verbose || params debugLibcache) {
            process getCommandLine() println()
        }

        output := process getOutput()

        if(params veryVerbose || params debugLibcache) {
            output print()
        }

        if(doCacheinfo) {
            _write()
        }
    }

}

/**
   Information about an ooc module in an archive
 */
ArchiveModule: class {

    oocPath: String
    lastModified: Long
    module: Module
    archive: Archive

    types := HashMap<String, ArchiveType> new()

    /**
       Create info about a module
     */
    init: func ~fromModule (=module, =archive) {
        oocPath = module path + ".ooc"
        if(archive pathElement) {
            lastModified = File new(archive pathElement, oocPath) lastModified()
        } else {
            lastModified = -1
        }

        for(tDecl in module getTypes()) {
            archType := ArchiveType new(tDecl)
            types put(archType name, archType)
        }
    }

    /**
       Read info about an archive element from a .cacheinfo file
     */
    init: func ~fromFileReader(fR: FileReader, =archive) {
        oocPath = fR readLine()
        lastModified = fR readLine() toLong()

        typesSize := fR readLine() toInt()

        for(i in 0..typesSize) {
            archType := ArchiveType new(fR)
            types put(archType name, archType)
        }

        _getModule()
    }

    upToDate?: Bool {
        get {
            for(tDecl in module getTypes()) {
                archType := types get(tDecl getFullName())

                // if the type wasn't there last time - we're not up-to date!
                if(archType == null) {
                    name := tDecl getFullName()
                    if(name startsWith?("_") && (name endsWith?("_ctx") || name endsWith?("_ctxClass"))) {
                        continue // type wasn't there last time but we don't care, _ctx (closure) types aren't important
                    }
                    if(archive params debugLibcache) "Type %s wasn't there last time" printfln(tDecl getName())
                    return false
                }

                statVarIter   := archType staticVariables iterator()
                instanceVarIter := archType variables iterator()

                for (variable in tDecl getVariables()) {
                    if(variable isStatic) {
                        if(!statVarIter hasNext?()) {
                            if(archive params debugLibcache) "Static var %s has changed, %s not up-to-date\n" printfln(variable getName(), oocPath)
                            return false
                        }
                        next := statVarIter next()
                        if(next != variable getName()) {
                            if(archive params debugLibcache) "Static var %s has changed, %s not up-to-date\n" printfln(variable getName(), oocPath)
                            return false
                        }
                    } else {
                        if(!instanceVarIter hasNext?()) {
                            if(archive params debugLibcache) "Instance var %s has changed, %s not up-to-date\n" printfln(variable getName(), oocPath)
                            return false
                        }
                        next := instanceVarIter next()
                        if(next != variable getName()) {
                            if(archive params debugLibcache) "Instance var %s has changed, %s not up-to-date\n" printfln(variable getName(), oocPath)
                            return false
                        }
                    }
                }
                if(statVarIter hasNext?()) {
                    if(archive params debugLibcache) "Less static vars, %s not up-to-date\n" printfln(oocPath)
                    return false
                }
                if(instanceVarIter hasNext?()) {
                    if(archive params debugLibcache) "Less instance vars, %s not up-to-date\n" printfln(oocPath)
                    return false
                }

                functionIter := archType functions iterator()

                for (function in tDecl getFunctions()) {
                    if(!functionIter hasNext?()) {
                        if(archive params debugLibcache) "Function %s has changed (%d vs %d), %s not up-to-date\n" printfln(function getFullName(), archType functions getSize(), tDecl getFunctions() getSize(), oocPath)
                        return false
                    }
                    next := functionIter next()
                    if(next != function getFullName()) {
                        if(archive params debugLibcache) "Function %s has changed (vs %s), %s not up-to-date\n" printfln(function getFullName(), next, oocPath)
                        return false
                    }
                }

                if(functionIter hasNext?()) {
                    if(archive params debugLibcache) "Less methods, %s not up-to-date\n" printfln(oocPath)
                    return false
                }
            }

            return true
        }
    }

    /**
       Retrieve the module from the AstBuilder's cache, and throw
       an exception if it's not found
     */
    _getModule: func {
        oocFile := File new(archive pathElement, oocPath)
        if(oocFile exists?()) {
            module = AstBuilder cache get(oocFile getAbsolutePath())
        }
    }

    /**
       Write info about this archive element to a .cacheinfo file
     */
    write: func (fW: FileWriter) {
        // ooc path
        // lastModified
        // number of types
        fW writef("%s\n%ld\n%d\n", oocPath, lastModified, types getSize())

        // write each type
        i := 0
        for(type in types) {
            type write(fW)
            i += 1
        }
    }

}

/**
   Information about an ooc type
 */
ArchiveType: class {

    name: String

    staticVariables := ArrayList<String> new()
    variables := ArrayList<String> new()
    functions := ArrayList<String> new()

    /**
       Create type info from a TypeDecl
     */
    init: func ~fromTypeDecl (typeDecl: TypeDecl) {
        name = typeDecl getFullName()

        for (vDecl in typeDecl getVariables()) {
            list := (vDecl isStatic() ? staticVariables : variables)
            list add(vDecl getName())
        }

        for (fDecl in typeDecl getFunctions()) {
            functions add(fDecl getFullName())
        }
    }

    init: func ~fromFileReader (fR: FileReader) {
        name = fR readLine()

        // read static variables
        staticVariablesSize := fR readLine() toInt()
        for(i in 0..staticVariablesSize) {
            staticVariables add(fR readLine())
        }

        // read instance variables
        variablesSize := fR readLine() toInt()
        for(i in 0..variablesSize) {
            variables add(fR readLine())
        }

        // read functions
        functionsSize := fR readLine() toInt()
        for(i in 0..functionsSize) {
            functions add(fR readLine())
        }
    }

    write: func (fW: FileWriter) {
        fW writef("%s\n", name)

        // write static variables
        fW writef("%d\n", staticVariables getSize())
        for(variable in staticVariables) {
            fW writef("%s\n", variable)
        }

        // write instance variables
        fW writef("%d\n", variables getSize())
        for(variable in variables) {
            fW writef("%s\n", variable)
        }

        // write functions
        fW writef("%d\n", functions getSize())
        for(function in functions) {
            fW writef("%s\n", function)
        }
    }

}


