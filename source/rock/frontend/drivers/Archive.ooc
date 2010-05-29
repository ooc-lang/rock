import structs/[List, ArrayList, HashMap]

import io/[File, FileReader, FileWriter], os/Process

import ../[AstBuilder, BuildParams]

import ../../middle/[Module, TypeDecl, VariableDecl, FunctionDecl]

/**
   Manage .a files stored in .libs/, with their .a.cacheinfo
   files, can check up-to-dateness, add files, etc.
    
   :author: Amos Wenger (nddrylliog)
 */
Archive: class {

    map := static HashMap<Module, Archive> new()

    /** Path of the file where the archive is stored */
    outlib: String
    
    /** List of elements contained in the archive */
    elements := HashMap<String, ArchiveModule> new()
    
    /** List of elements to add to the archive when save() is called */
    toAdd := ArrayList<Module> new()
    
    /** Create a new Archive */
    init: func ~archive (=outlib) {
        if(File new(outlib) exists() && File new(outlib + ".cacheinfo") exists()) {
            _read()
        }
    }
    
    _read: func {
        fR := FileReader new(outlib + ".cacheinfo")
        cacheSize := fR readLine() toInt()
        
        for(i in 0..cacheSize) {
            element := ArchiveModule new(fR)
            if(element module == null) {
                map put(element module, this)
                elements put(element oocPath, element)
            } else {
                // If the element' module is null, it means that there are files
                // in the cache that we don't need to compile for this run.
                // Typically, the compiler has been launched several times
                // in the same folder for different .ooc files
                
                // If it contains a main, then it *needs* to be removed
                // from the archive file, otherwise there would be two mains
                // and the resulting app would probably launch the wrong main..
                
                // For now, we remove it anyway - later, we might want to check
                // if it does really contain a main
                printf("Removing %s from archive %s\n", element oocPath, outlib)
                
                // turn "blah/file.ooc" into "file.o". GOTCHA: later we might
                // wanna produce .o files with better names, so that there are
                // no conflicts when storing them in archive files.
                
                name := File new(element oocPath) name()
                
                args := ["ar", "d", outlib, name substring(0, name length() - 2)] as ArrayList<String>
                args T = String
                args join(" ") println()
                Process new(args) execute()
            }
        }
        fR close()
    }
    
    _write: func {
        fW := FileWriter new(outlib + ".cacheinfo")
        
        fW writef("%d\n", elements size())
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
            File new(outlib) exists()
        }
    }
    
    /**
       Check if a module is present and up-to-date
       in the given archive.
     */
    upToDate?: func (module: Module) -> Bool {
        _upToDate?(module, ArrayList<Module> new(), true)
    }
    
    _upToDate?: func (module: Module, done: List<Module>, ourself: Bool) -> Bool {
        done add(module)
        
        oocPath := module getOocPath()
        element := elements get(oocPath)
        if(element == null) {
            //printf("%s not in the cache, recompiling...\n", module getFullName())
            return false
        }

        lastModified := File new(oocPath) lastModified()
        if(lastModified != element lastModified) {
            //printf("%s out-of-date, recompiling... (%d vs %d, oocPath = %s)\n", module getFullName(), lastModified, element lastModified, oocPath)
            if(ourself || !element upToDate?) {
                return false
            }
        }
        
        for(imp in module getAllImports()) {
            if(done contains(imp getModule())) continue
            
            subArchive := map get(imp getModule())
            
            if(subArchive == null || !subArchive _upToDate?(imp getModule(), done, false)) {
                //printf("%s recompiling because of dependency %s (subArchive = %s)\n",
                //   module getFullName(), imp getModule() getFullName(), subArchive ? subArchive outlib : "(nil)")
                return false
            }
        }
        
        return true
    }
    
    /**
       Must be called after add calls to apply the changes
       to the archives.
     */
    save: func (params: BuildParams) {
        if(toAdd isEmpty()) return
        
        args := ArrayList<String> new()
        args add("ar") // GNU ar tool, manages archives
        
        if(!this exists?) {
            // if the archive doesn't exist, c = create it
            args add("crs") // r = add with replacement, s = create/update index
        } else {
            args add("rs") // r = add with replacement, s = create/update index
        }
        
        // output path
        args add(outlib)
        
        for(module in toAdd) {
            // we add .o (object files) to the archive
            oPath := "%s%c%s.o" format(params outPath path, File separator, module getPath(""))
            args add(oPath)
            
            element := ArchiveModule new(module)
            
            elements remove(element oocPath) // replace
            elements put(element oocPath, element)
        }
        toAdd clear()
        
        if(params verbose) {
            printf("%s archive %s\n", this exists? ? "Updating" : "Creating", outlib)
            args join(" ") println()
        }
        
        File new(outlib) parent() mkdirs()
        Process new(args) getOutput() print()
        
        _write()
    }
    
}

/**
   Information about an ooc module in an archive
 */
ArchiveModule: class {
    
    oocPath: String
    lastModified: Long
    module: Module
    
    types := HashMap<String, ArchiveType> new()
    
    /**
       Create info about a module
     */
    init: func ~fromModule (=module) {
        oocPath = module getOocPath()
        lastModified = File new(oocPath) lastModified()
        
        for(tDecl in module getTypes()) {
            archType := ArchiveType new(tDecl)
            types put(archType name, archType)
        }
    }
    
    /**
       Read info about an archive element from a .cacheinfo file
     */
    init: func ~fromFileReader(fR: FileReader) {
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
                
                statVarIter   := archType staticVariables iterator()
                instanceVarIter := archType variables iterator()
                
                for (variable in tDecl getVariables()) {
                    if(variable isStatic) {
                        if(!statVarIter hasNext()) {
                            //printf("Static var %s has changed, %s not up-to-date\n", variable getName(), oocPath)
                            return false
                        }
                        next := statVarIter next()
                        if(next != variable getName()) {
                            //printf("Static var %s has changed, %s not up-to-date\n", variable getName(), oocPath)
                            return false
                        }
                    } else {
                        if(!instanceVarIter hasNext()) {
                            //printf("Instance var %s has changed, %s not up-to-date\n", variable getName(), oocPath)
                            return false
                        }
                        next := instanceVarIter next()
                        if(next != variable getName()) {
                            //printf("Instance var %s has changed, %s not up-to-date\n", variable getName(), oocPath)
                            return false
                        }
                    }
                }
                if(statVarIter hasNext()) {
                    //printf("Less static vars, %s not up-to-date\n", oocPath)
                    return false
                }
                if(instanceVarIter hasNext()) {
                    //printf("Less instance vars, %s not up-to-date\n", oocPath)
                    return false
                }
                
                functionIter := archType functions iterator()
                
                for (function in tDecl getFunctions()) {
                    if(!functionIter hasNext()) {
                        //printf("Function %s has changed, %s not up-to-date\n", function getFullName(), oocPath)
                        return false
                    }
                    next := functionIter next()
                    if(next != function getFullName()) {
                        //printf("Function %s has changed, %s not up-to-date\n", function getFullName(), oocPath)
                        return false
                    }
                }
                
                if(functionIter hasNext()) {
                    //printf("Less methods, %s not up-to-date\n", oocPath)
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
        module = AstBuilder cache get(oocPath)
        if(module == null) {
            realPath := File new(oocPath) getAbsolutePath()
            module = AstBuilder cache get(realPath)
        }
    }

    /**
       Write info about this archive element to a .cacheinfo file
     */
    write: func (fW: FileWriter) {
        // ooc path
        // lastModified
        // number of types
        fW writef("%s\n%ld\n%d\n", oocPath, lastModified, types size())
     
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
        fW writef("%d\n", staticVariables size())
        for(variable in staticVariables) {
            fW writef("%s\n", variable)
        }
        
        // write instance variables
        fW writef("%d\n", variables size())
        for(variable in variables) {
            fW writef("%s\n", variable)
        }
        
        // write functions
        fW writef("%d\n", functions size())
        for(function in functions) {
            fW writef("%s\n", function)
        }
    }
    
}


