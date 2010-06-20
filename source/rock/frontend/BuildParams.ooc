import io/File, os/Env
import structs/ArrayList

import compilers/AbstractCompiler
import PathList
import DistLocator, SdkLocator
import ../middle/Module

BuildParams: class {
    
    fatalError := static true
    
    additionals  := ArrayList<String> new() 
    compilerArgs := ArrayList<String> new() 
    
    /* Builtin defines */
	GC_DEFINE := static const "__OOC_USE_GC__"
    
    init: func {
        path := Env get("OOC_LIBS")
        if(path == null) {
            // TODO: find other standard paths for other OSes
            path = "/usr/lib/ooc/"
        }
        libsPath = File new(path)
        
        // use the GC by default =)
		defines add(This GC_DEFINE)
    }
    
    compiler: AbstractCompiler = null
    
    distLocation := DistLocator locate()
    sdkLocation := SdkLocator locate()
    
    sourcePath := PathList new()
    libPath := PathList new()
    incPath := PathList new()
    
    libsPath: File
    
    outPath: File = File new("rock_tmp")
    
    // if non-null, use 'linker' as the last step of the compile process, with driver=sequence
	linker := null as String
    
    // threads used by the sequence driver
    sequenceThreads := 1
    
    // list of symbols defined e.g. by -Dblah
	defines := ArrayList<String> new()
    
    // Path to place the binary
    binaryPath: String = ""

    // Path of the text editor to run when an error is encountered in an ooc file 
    editor: String = ""
    
    // Remove the rock_tmp/ directory after the C compiler has finished
    clean := true
    
    // Cache libs in `libcachePath` directory
    libcache := true
    
    // Path to store cache-libs
    libcachePath := ".libs"
    
    // Add debug info to the generated C files (e.g. -g switch for gcc)
    debug := false
    
    // Displays which files it parses, and a few debug infos
    verbose := false
    
    // Display compilation statistics
    stats := false
    
    // More debug messages
    veryVerbose := false
    
    // Debugging purposes
    debugLoop := false
    
    // Tries to find types/functions in not-imported nodules, etc. Disable with -noshit
    helpful := true
    
    // Displays [ OK ] or [FAIL] at the end of the compilation
    //shout := false
    shout := true // true as long as we're debugging
    
    // If false, output .o files. Otherwise output exectuables
    link := true
    
    // Run files after compilation
    run := false
    
    // Display compilation times for all .ooc files passed to the compiler
    timing := false
    
    // Compile once, then wait for the user to press enter, then compile again, etc.
    slave := false

    // Should link with libgc at all.
    enableGC := true
    
    // link dynamically with libgc (Boehm)
    dynGC := false
    
    // add #line directives in the generated .c for debugging.
    // depends on "debug" flag
    lineDirectives := true
    
    // either "32" or "64"
    arch: String = ""
    
    // name of the entryPoint to the program
    entryPoint := "main"
    
    // if non-null, will create a static library with 'ar rcs <outlib> <all .o files>'
	outlib := null as String
    
    // add a main method if there's none in the specified ooc file
	defaultMain := true
    
    // maximum number of rounds the {@link Tinkerer} will do before blowing up.
    blowup: Int = 32
    
    // include or not lang/ packages (for testing)
    includeLang := true
    
    // dynamic libraries to be linked into the executable
    dynamicLibs := ArrayList<String> new()

    // backend; can be "c" or "json".
    backend: String = "c"
    
    defineSymbol: func (symbol: String) {
		if(!defines contains(symbol)) {
			defines add(symbol)
		}
	}
	
	undefineSymbol: func (symbol: String) {
		defines remove(symbol)
	}
    
}
