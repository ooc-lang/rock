import structs/[List, ArrayList]

import io/File, os/Process

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
    toAdd := ArrayList<ArchiveElement> new()
    
    /** Create a new Archive */
    init: func ~archive (=outlib) {}
    
    /**
       Schedule the addition of a module to this archive.
       save() must be called afterwards so that bunches of
       modules can be added all at once.
     */
    add: func (module: Module) {
        toAdd add(ArchiveElement new(module))
    }
    
    /**
       Check if a module is present and up-to-date
       in the given archive.
     */
    isUpToDate: func (module: Module) -> Bool {
        
    }
    
    /**
       Must be called after add calls to apply the changes
       to the archives.
     */
    save: func (params: BuildParams) -> {
        args := ArrayList<String> new()
        args add("ar") // GNU ar tool, manages archives
        args add("rs") // r = add with replacement, s = create/update index
        
        if(!File new(outlib) exists()) {
            // if the archive doesn't exist, c = create it
            args add("c")
        }
        
        // output path
        args add(outlib)
        
        for(element in toAdd) {
            // we add .o (object files) to the archive
            oPath := "%s%s%s.o" format(params outPath, File separator, module getPath(""))
            args add(oPath)
            
            elements put(element oocPath, element)
        }
        
        Process new(args) getOutput() println()
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
    
}
