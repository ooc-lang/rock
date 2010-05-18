import structs/[List, ArrayList, HashMap]

import io/[File, FileReader, FileWriter], os/Process

import ../BuildParams
import ../../middle/[Module]

/**
   Manage .a files stored in .libs/, with their .a.cacheinfo
   files, can check up-to-dateness, add files, etc.
    
   :author: Amos Wenger (nddrylliog)
 */
Archive: class {

    /** Path of the file where the archive is stored */
    outlib: String
    
    /** List of elements contained in the archive */
    elements := HashMap<String, ArchiveElement> new()
    
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
            name := fR readLine()
            lastModified := fR readLine() toLong()
            elements put(name, ArchiveElement new(name, lastModified))
        }
        fR close()
    }
    
    _write: func {
        fW := FileWriter new(outlib + ".cacheinfo")
        fW writef("%d\n", elements size())
        
        for(element in elements) {
            fW writef("%s\n%ld\n", element oocPath, element lastModified)
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
    }
    
    /**
       Check if a module is present and up-to-date
       in the given archive.
     */
    isUpToDate: func (module: Module) -> Bool {
        oocPath := module getOocPath()
        
        element := elements get(oocPath)
        
        if(element == null) return false
        if(File new(oocPath) lastModified() != element lastModified) return false
        
        return true
    }
    
    /**
       Must be called after add calls to apply the changes
       to the archives.
     */
    save: func (params: BuildParams) {
        args := ArrayList<String> new()
        args add("ar") // GNU ar tool, manages archives
        args add("rs") // r = add with replacement, s = create/update index
        
        if(!File new(outlib) exists()) {
            // if the archive doesn't exist, c = create it
            args add("c")
        }
        
        // output path
        args add(outlib)
        
        for(module in toAdd) {
            // we add .o (object files) to the archive
            oPath := "%s%s%s.o" format(params outPath, File separator, module getPath(""))
            args add(oPath)
            
            element := ArchiveElement new(module)
            elements put(element oocPath, element)
        }
        
        Process new(args) getOutput() println()
        
        _write()
    }
    
}

/**
   Information about an ooc module in an archive
 */
ArchiveElement: class {
    
    oocPath: String
    lastModified: Long
    
    init: func ~fromModule (module: Module) {
        oocPath = module getOocPath()
        lastModified = File new(oocPath) lastModified()
    }
    
    init: func ~pathLastMod(=oocPath, =lastModified) {}
    
}
