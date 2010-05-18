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
        printf("Added module %s to archive %s\n", module getFullName(), outlib)
        toAdd add(module)
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
            
            element := ArchiveElement new(module)
            
            elements remove(element oocPath) // replace
            elements put(element oocPath, element)
        }
        toAdd clear()
        
        if(params verbose) {
            printf("%s archive %s\n", this exists? ? "Updating" : "Creating", outlib)
            args join(" ") println()
        }
        
        File new(outlib) parent() mkdirs()
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
