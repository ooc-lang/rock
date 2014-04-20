
// sdk stuff
import structs/[List, ArrayList, HashMap]
import io/[File, FileReader, FileWriter], os/[Process, Env]

// our stuff
import SourceFolder
import rock/RockVersion
import rock/frontend/[AstBuilder, BuildParams, PathList, Target]
import rock/middle/[Module, TypeDecl, VariableDecl, FunctionDecl]
import rock/middle/algo/ImportClassifier
import rock/backend/cnaughty/ModuleWriter

/**
 * Manage .a files stored in .libs/, with their .cacheinfo
 * files, can check up-to-dateness, add files, etc.
 */
Archive: class {

    supportedVersion := static "0.5"

    map := static HashMap<Module, Archive> new()
    dirtyModules := ArrayList<Module> new()
    structuralDirties := ArrayList<Module> new()

    /** Source folder that this archive is for */
    sourceFolder: SourceFolder

    /** Location of the source-folder in the file system. */
    pathElement: File

    /** Path of the file where the archive is stored */
    outlib: String

    /** Path of the .cacheinfo file */
    cacheInfoPath: String

    /** The build parameters */
    params: BuildParams

    /** A string representation of compiler options */
    compilerArgs: String

    /** Map of elements contained in the archive */
    elements := HashMap<String, ArchiveModule> new()

    /** List of modules contained in this archive */
    modules := ArrayList<Module> new()

    /** List of object files to add to this archive */
    objectFiles := ArrayList<String> new()

    /** Write .cacheinfo files or not */
    doCacheinfo := true

    /** Create a new Archive */
    init: func ~archiveCacheinfo (=sourceFolder, =outlib, =params, =doCacheinfo, =pathElement) {
        compilerArgs = params getArgsRepr()
        cacheInfoPath = outlib[0..-3] + ".cache"
        if(doCacheinfo) {
            if(File new(outlib) exists?() && File new(cacheInfoPath) exists?()) {
                _read()
            } else {
                debug("Either %s or %s don't exist", outlib, cacheInfoPath)
            }
        }
    }

    debug: func ~str (msg: String) {
        if (!params debugLibcache) {
            return
        }

        "[%s] %s" printfln(cacheInfoPath, msg)
    }

    debug: func ~var (msg: String, args: ...) {
        debug(msg format(args))
    }

    _readHeader: func (fR: FileReader) -> Bool {
        cacheversion  := fR readLine()
        if(cacheversion != "cacheversion") {
            debug("malformed cache file")
            return false
        }

        readVersion := fR readLine()
        if(readVersion != supportedVersion) {
            debug("Wrong version %s. We only read version %s.", readVersion, supportedVersion)
            return false
        }

        readCompilerArgs := fR readLine()
        if(readCompilerArgs != compilerArgs) {
            debug("Wrong compiler args %s. We have args %s", readCompilerArgs, compilerArgs)
            return false
        }

        readCompilerVersion := fR readLine()
        compilerVersion := RockVersion getName()
        if(readCompilerVersion != compilerVersion) {
            debug("Wrong compiler version %s. We have version %s", readCompilerArgs, compilerVersion)
            return false
        }

        true
    }

    _read: func {
        fR := FileReader new(cacheInfoPath)
        debug("Reading cache info")

        if(!_readHeader(fR)) {
            debug("Couldn't read header")
            fR close()
            return
        }

        cacheSize := fR readLine() toInt()
        parsedModules := ArrayList<ArchiveModule> new()

        for(i in 0..cacheSize) {
            parsedModules add(ArchiveModule new(fR, this))
        }
        fR close()

        upToDate := true
        for (element in parsedModules) {
            if(element module == null) {
                if (!element hasMain?) {
                    // it's okay
                    continue
                }

                upToDate = false

                // If we didn't find the module, it should be removed from the archive.
                debug("Removing %s from archive %s", element oocPath, outlib)

                args := ArrayList<String> new()
                args add(params ar)

                args add("d")
                if (params veryVerbose || params debugLibcache) {
                    args add("v")
                }
                args add(outlib)
                args add(element objectPath)

                output := Process new(args) getOutput()

                if(params debugLibcache) {
                    args join(" ") println()
                    output println()
                }
            } else {
                map put(element module, this)
                elements put(element oocPath, element)
            }
        }

        if (!upToDate) {
            _write()
        }
    }

    _write: func {
        fW := FileWriter new(cacheInfoPath)

        fW writef("cacheversion\n%s\n", supportedVersion)
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
    add: func (module: Module, objectPath: String) {
        modules add(module)
        map put(module, this)
        objectFiles add(objectPath)
    }

    /**
       Schedule the addition of an object file to this
       archive.
     */
    add: func ~additional (objectPath: String) {
        objectFiles add(objectPath)
    }

    add: func ~archive (archive: Archive) {
        objectFiles add(archive outlib)
    }

    /**
     * :return: true if the archive has already been stored to disk once
     */
    exists?: Bool {
        get {
            if(!doCacheinfo) return false
            if(!File new(outlib) exists?()) return false
            if(!File new(cacheInfoPath) exists?()) return false

            fR := FileReader new(cacheInfoPath)
            result := _readHeader(fR)
            fR close()
            return result
        }
    }

    updateDirtyModules: func -> List<Module> {

        modules := sourceFolder modules
        transModules := ArrayList<Module> new()
        cleanModules := ArrayList<Module> new()
        cleanModules addAll(modules)

        dirtyModules clear()
        structuralDirties clear()

        running := true
        while(running) {
            debug("Analyzing %s, %d cleanModules, %d dirtyModules",
                pathElement path, cleanModules getSize(), dirtyModules getSize())

            for(module in cleanModules) {
                subArchive := map get(module)
                if(!subArchive) {
                    debug("%s is dirty because we can't find the archive", module getFullName())
                    transModules add(module); continue
                }
                oocPath := module path + ".ooc"
                element := subArchive elements get(oocPath)
                if(!element) {
                    debug("%s is dirty because we can't find the element in archive %s",
                        module getFullName(), subArchive pathElement path)
                    transModules add(module); continue
                }
                if(!element upToDate?) {
                    debug("%s is dirty because of element %s", module getFullName(), element oocPath)
                    subArchive elements put(oocPath, ArchiveModule new(module, subArchive))
                    structuralDirties add(module)
                    transModules add(module)
                    continue
                }

                oocFile := File new(subArchive pathElement, oocPath)
                lastModified := oocFile lastModified()
                if(lastModified != element lastModified) {
                    debug("%s out-of-date, recompiling... (%d vs %d, oocPath = %s)",
                        module getFullName(), lastModified, element lastModified, oocPath)
                    transModules add(module); continue
                }

                trans := false

                ImportClassifier classify(module)
                for(imp in module getAllImports()) {
                    candidate := imp getModule()
                    archive := map get(candidate)
                    if(archive && archive structuralDirties contains?(candidate)) {
                        debug("%s is dirty because of import %s", module getFullName(),
                            candidate getFullName())
                        if(!trans) {
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
                debug("[%s] We have %d transmodules to handle", pathElement path, transModules size)
                for (module in transModules) {
                    debug(" - %s", module getFullName())
                    dirtyModules add(module)
                    cleanModules remove(module)
                }
                transModules clear()
            }
        }

        dirtyModules

    }

    /**
       Must be called after add calls to apply the changes
       to the archives.
     */
    save: func (params: BuildParams, symbolTable, thin: Bool) {
        // now build static libraries for all source folders
        debug("Saving...")

        if (modules empty?() && objectFiles empty?()) {
            debug("Up-to-date, skipping.")
            return
        }

        // update .cacheinfo
        for (module in modules) {
            element := ArchiveModule new(module, this)
            elements put(element oocPath, element)
        }

        // update .a using GNU ar
        args := ArrayList<String> new()
        args add(params ar)

        flags := ArrayList<String> new()

        if(!this exists?) {
            flags add("c") // create
        }

        flags add("r") // insert with replacement

        if (symbolTable) {
            flags add("s")
        }

        if (thin) {
            // Apple's linker thinks -T means truncate. Who's living
            // in the 18th century? It's OpenStep's bastard child!
            // OpenBSD's binutils (binutils-2.15) predates ar -T.
            if (params target != Target OSX && params target != Target OPENBSD) {
                flags add("T")
            }
        }

        if (params debugLibcache) {
            flags add("v")
        }

        args add(flags join(""))

        // output path
        args add(outlib)

        for (objectFile in objectFiles) {
            args add(objectFile)
        }

        File new(outlib) parent mkdirs()
        process := Process new(args)

        if(params debugLibcache) {
            process getCommandLine() println()
        }

        output := process getOutput()

        if(params debugLibcache) {
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

    oocPath, objectPath: String
    lastModified: Long
    module: Module
    archive: Archive

    types := HashMap<String, ArchiveType> new()
    functions := ArrayList<String> new()
    hasMain? ::= functions contains?("main")

    /**
       Create info about a module
     */
    init: func ~fromModule (=module, =archive) {
        oocPath = module path + ".ooc"
        objectPath = archive sourceFolder relativeObjectPath(module)

        if(archive pathElement) {
            lastModified = File new(archive pathElement, oocPath) lastModified()
        } else {
            lastModified = -1
        }

        for (tDecl in module getTypes()) {
            archType := ArchiveType new(tDecl)
            types put(archType name, archType)
        }

        module getFunctions() each(|key, fDecl|
            functions add(fDecl getFullName())
        )
    }

    /**
       Read info about an archive element from a .cacheinfo file
     */
    init: func ~fromFileReader(fR: FileReader, =archive) {
        oocPath = fR readLine()
        objectPath = fR readLine()
        lastModified = fR readLine() toLong()

        typesSize := fR readLine() toInt()
        for(i in 0..typesSize) {
            archType := ArchiveType new(fR)
            types put(archType name, archType)
        }

        functionsSize := fR readLine() toInt()
        for(i in 0..functionsSize) {
            fName := fR readLine()
            functions add(fName)
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
                            if(archive params debugLibcache) "Static var %s has changed, %s not up-to-date" printfln(variable getName(), oocPath)
                            return false
                        }
                        next := statVarIter next()
                        if(next != variable getName()) {
                            if(archive params debugLibcache) "Static var %s has changed, %s not up-to-date" printfln(variable getName(), oocPath)
                            return false
                        }
                    } else {
                        if(!instanceVarIter hasNext?()) {
                            if(archive params debugLibcache) "Instance var %s has changed, %s not up-to-date" printfln(variable getName(), oocPath)
                            return false
                        }
                        next := instanceVarIter next()
                        if(next != variable getName()) {
                            if(archive params debugLibcache) "Instance var %s has changed, %s not up-to-date" printfln(variable getName(), oocPath)
                            return false
                        }
                    }
                }
                if(statVarIter hasNext?()) {
                    if(archive params debugLibcache) "Fewer static vars, %s not up-to-date" printfln(oocPath)
                    return false
                }
                if(instanceVarIter hasNext?()) {
                    if(archive params debugLibcache) "Fewer instance vars, %s not up-to-date" printfln(oocPath)
                    return false
                }

                functionIter := archType functions iterator()

                for (function in tDecl getFunctions()) {
                    if(!functionIter hasNext?()) {
                        if(archive params debugLibcache) "Function %s has changed (%d vs %d), %s not up-to-date" printfln(function getFullName(), archType functions getSize(), tDecl getFunctions() getSize(), oocPath)
                        return false
                    }
                    next := functionIter next()
                    if(next != function getFullName()) {
                        if(archive params debugLibcache) "Function %s has changed (vs %s), %s not up-to-date" printfln(function getFullName(), next, oocPath)
                        return false
                    }
                }

                if(functionIter hasNext?()) {
                    if(archive params debugLibcache) "Fewer methods, %s not up-to-date" printfln(oocPath)
                    return false
                }
            }

            return true
        }
    }

    /**
     * Retrieve the module from the AstBuilder's cache
     */
    _getModule: func {
        oocFile := File new(archive pathElement, oocPath)
        if(oocFile exists?()) {
            module = AstBuilder cache get(oocFile getAbsolutePath())
        } else {
            archive debug("Couldn't find ooc file %s", oocFile path)
        }
    }

    /**
       Write info about this archive element to a .cacheinfo file
     */
    write: func (fW: FileWriter) {
        // ooc path
        // object path
        // lastModified
        // number of types
        fW writef("%s\n%s\n%ld\n%d\n", oocPath, objectPath, lastModified, types size)

        // write each type
        for (type in types) {
            type write(fW)
        }

        // write each function
        fW writef("%d\n", functions size)
        for (f in functions) {
            fW writef("%s\n")
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


