import io/File, os/Env
import structs/ArrayList

import compilers/AbstractCompiler
import PathList
import DistLocator, SdkLocator
import ../middle/Module

BuildParams: class {
    
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
    clean: Bool = true
    
    // Add debug info to the generated C files (e.g. -g switch for gcc)
    debug: Bool = false
    
    // Displays which files it parses, and a few debug infos
    verbose: Bool = false
    
    // More debug messages
    veryVerbose: Bool = false
    
    // Debugging purposes
    debugLoop: Bool = false
    
    // Displays [ OK ] or [FAIL] at the end of the compilation
    //shout: Bool = false
    shout: Bool = true // true as long as we're debugging
    
    // If false, output .o files. Otherwise output exectuables
    link: Bool = true
    
    // Run files after compilation
    run: Bool = false
    
    // Display compilation times for all .ooc files passed to the compiler
    timing: Bool = false
    
    // Compile once, then wait for the user to press enter, then compile again, etc.
    slave: Bool = false

    // Should link with libgc at all.
    enableGC: Bool = true
    
    // link dynamically with libgc (Boehm)
    dynGC: Bool = false
    
    // add #line directives in the generated .c for debugging.
    // depends on "debug" flag
    lineDirectives: Bool = true
    
    // either "32" or "64"
    arch: String = ""
    
    // if non-null, will create a static library with 'ar rcs <outlib> <all .o files>'
	outlib := null as String
    
    // maximum number of rounds the {@link Tinkerer} will do before blowing up.
    blowup: Int = 16
    
    includeLang := true
    
    dynamicLibs := ArrayList<String> new()

    // backend; can be "c" or "json".
    backend: String = "c"
    
    /**
     * Build the output path for an .ooc file.
     * For example, if the file was found in
     *    `<sourcepath>/my/package/file.ooc`
     * The output path will be built like this:
     *     <outpath>/my/package/file<extension>
     */
    getOutputPath: func (module: Module, extension: String) -> String {
        outPath path + File separator + module getPath(extension)
    }
    
    defineSymbol: func (symbol: String) {
		if(!defines contains(symbol)) {
			defines add(symbol)
		}
	}
	
	undefineSymbol: func (symbol: String) {
		defines remove(symbol)
	}
    
}
