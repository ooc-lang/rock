import rock/RockVersion

import structs/[List, ArrayList, HashMap]

import io/[File, FileReader, FileWriter], os/[Process, Env]

import ../[AstBuilder, BuildParams, PathList]

import ../../middle/[Module, TypeDecl, VariableDecl, FunctionDecl]
import ../../backend/cnaughty/ModuleWriter

/**
   Manage .a files stored in .libs/, with their .a.cacheinfo
   files, can check up-to-dateness, add files, etc.

   :author: Amos Wenger (nddrylliog)
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

    /** List of elements contained in the archive */
    elements := HashMap<String, ArchiveModule> new()

    /** List of elements to add to the archive when save() is called */
    toAdd := ArrayList<Module> new()

    /** Write .cacheinfo files or not */
    doCacheinfo := true

    /** Create a new Archive */
    init: func ~archive (.sourceFolder, .outlib, .params) {
        init(sourceFolder, outlib, params, true)
    }

    init: func ~archiveCacheinfo (=sourceFolder, =outlib, =params, =doCacheinfo) {
        compilerArgs = params getArgsRepr()
        if(doCacheinfo) {
            pathElement = params sourcePath get(sourceFolder)
            if(File new(outlib) exists?() && File new(outlib + ".cacheinfo") exists?()) {
                _read()
            }
        }
    }

    _readHeader: func (fR: FileReader) -> Bool {
        cacheversion     := fR readLine()
        if(cacheversion != "cacheversion") {
            if(params veryVerbose || params debugLibcache) {
                "Malformed cacheinfo file %s.cacheinfo, ignoring." format(outlib toCString()) println()
            }
            return false
        }

        readVersion      := fR readLine()
        if(readVersion != version) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong version %s for %s.cacheinfo. We only read version %s. Ignoring" format(readVersion toCString(), outlib toCString(), version toCString()) println()
            }
            return false
        }

        readCompilerArgs := fR readLine()
        if(readCompilerArgs != compilerArgs) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong compiler args '%s' for %s.cacheinfo. We have args '%s'. Ignoring" format(readCompilerArgs toCString(), outlib toCString(), compilerArgs toCString()) println()
            }
            return false
        }

        readCompilerVersion := fR readLine()
        if(readCompilerVersion != RockVersion getName()) {
            if(params veryVerbose || params debugLibcache) {
                "Wrong compiler version '%s' for %s.cacheinfo. We have version '%s'. Ignoring" format(readCompilerVersion toCString(), outlib toCString(), RockVersion getName() toCString()) println()
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
                    printf("Removing %s from archive %s\n", element oocPath toCString(), outlib toCString())
                }

                // turn "blah/file.ooc" into "blah_file.o"
                name := element oocPath replaceAll(File separator, '_')

                args := ArrayList<String> new()
                args add("ar") .add((params veryVerbose || params debugLibcache) ? "dv" : "d"). add(outlib). add(name substring(0, name length() - 2))
                output := Process new(args) getOutput()

                if(params veryVerbose || params debugLibcache) {
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

        fW writef("cacheversion\n%s\n", version toCString())
        fW writef("%s\n", compilerArgs toCString())
        fW writef("%s\n", RockVersion getName() toCString())
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
        toAdd add(module)
        map put(module, this)
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
                "Analyzing %s, %d cleanModules, %d dirtyModules" format(pathElement path toCString(), cleanModules getSize(), dirtyModules getSize()) println()
            }

            for(module in cleanModules) {
                subArchive := map get(module)
                if(!subArchive) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s is dirty because we can't find the archive" format(module getFullName() toCString()) println()
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
                        "%s is dirty because we can't find the element in archive %s" format(module getFullName() toCString(), subArchive pathElement path toCString()) println()
                    }
                    if(dotOutput) {
                        dotFile write("\""). write(module simpleName). write("\""). write(" -> "). write("\"ElementNotInArchive\";\n")
                    }
                    transModules add(module); continue
                }
                if(!element upToDate?) {
                    if(params veryVerbose || params debugLibcache) {
                        "%s is dirty because of element" format(module getFullName() toCString()) println()
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
                        "%s out-of-date, recompiling... (%d vs %d, oocPath = %s)" format (module getFullName() toCString(), lastModified, element lastModified, oocPath toCString()) println()
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
                            "%s is dirty because of import %s" format(module getFullName() toCString(), candidate getFullName() toCString()) println()
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
                    "[%s] We have %d transmodules to handle" format(pathElement path toCString(), transModules getSize()) println()
                }
                for (module in transModules) {
                    if(params veryVerbose || params debugLibcache) {
                        " - %s" format(module getFullName() toCString()) println()
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
    save: func (params: BuildParams) {
        //"Saving %s" format(pathElement path toCString()) println()

        args := ArrayList<String> new()
        args add("ar") // GNU ar tool, manages archives

        if(!this exists?) {
            // if the archive doesn't exist, c = create it
            args add((params veryVerbose || params debugLibcache) ? "crs" : "crsv") // c = create, r = add with replacement, s = create/update index
        } else {
            args add((params veryVerbose || params debugLibcache) ? "rs" : "rsv") // r = add with replacement, s = create/update index
        }

        // output path
        args add(outlib)

        for(module in toAdd) {
            // we add .o (object files) to the archive
            oPath := "%s%c%s.o" format(params outPath path toCString(), File separator, module path replaceAll(File separator, '_') toCString())
            args add(oPath)

            element := ArchiveModule new(module, this)
            elements put(element oocPath, element) // replace
        }
        toAdd clear()

        if(params veryVerbose || params debugLibcache) {
            printf("%s archive %s\n", (this exists? ? "Updating" : "Creating") toCString(), outlib toCString())
            args join(" ") println()
        }

        File new(outlib) parent() mkdirs()
        output := Process new(args) getOutput()

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
                    "Type %s wasn't there last time" format(tDecl getName() toCString()) println()
                    return false
                }

                statVarIter   := archType staticVariables iterator()
                instanceVarIter := archType variables iterator()

                for (variable in tDecl getVariables()) {
                    if(variable isStatic) {
                        if(!statVarIter hasNext?()) {
                            printf("Static var %s has changed, %s not up-to-date\n", variable getName() toCString(), oocPath toCString())
                            return false
                        }
                        next := statVarIter next()
                        if(next != variable getName()) {
                            printf("Static var %s has changed, %s not up-to-date\n", variable getName() toCString(), oocPath toCString())
                            return false
                        }
                    } else {
                        if(!instanceVarIter hasNext?()) {
                            printf("Instance var %s has changed, %s not up-to-date\n", variable getName() toCString(), oocPath toCString())
                            return false
                        }
                        next := instanceVarIter next()
                        if(next != variable getName()) {
                            printf("Instance var %s has changed, %s not up-to-date\n", variable getName() toCString(), oocPath toCString())
                            return false
                        }
                    }
                }
                if(statVarIter hasNext?()) {
                    printf("Less static vars, %s not up-to-date\n", oocPath toCString())
                    return false
                }
                if(instanceVarIter hasNext?()) {
                    printf("Less instance vars, %s not up-to-date\n", oocPath toCString())
                    return false
                }

                functionIter := archType functions iterator()

                for (function in tDecl getFunctions()) {
                    if(!functionIter hasNext?()) {
                        printf("Function %s has changed (%d vs %d), %s not up-to-date\n", function getFullName() toCString(), archType functions getSize(), tDecl getFunctions() getSize(), oocPath toCString())
                        return false
                    }
                    next := functionIter next()
                    if(next != function getFullName()) {
                        printf("Function %s has changed (vs %s), %s not up-to-date\n", function getFullName() toCString(), next toCString(), oocPath toCString())
                        return false
                    }
                }

                if(functionIter hasNext?()) {
                    printf("Less methods, %s not up-to-date\n", oocPath toCString())
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
        for (path in archive params sourcePath paths) {
            if (path getAbsoluteFile() name() == archive sourceFolder) {
                oocFile := File new(path getAbsolutePath(), oocPath)
                if(oocFile exists?()) {
                    module = AstBuilder cache get(oocFile getAbsolutePath())
                }
            }
        }
    }

    /**
       Write info about this archive element to a .cacheinfo file
     */
    write: func (fW: FileWriter) {
        // ooc path
        // lastModified
        // number of types
        fW writef("%s\n%ld\n%d\n", oocPath toCString(), lastModified, types getSize())

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
        fW writef("%s\n", name toCString())

        // write static variables
        fW writef("%d\n", staticVariables getSize())
        for(variable in staticVariables) {
            fW writef("%s\n", variable toCString())
        }

        // write instance variables
        fW writef("%d\n", variables getSize())
        for(variable in variables) {
            fW writef("%s\n", variable toCString())
        }

        // write functions
        fW writef("%d\n", functions getSize())
        for(function in functions) {
            fW writef("%s\n", function toCString())
        }
    }

}


