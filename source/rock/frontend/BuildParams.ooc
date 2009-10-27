import io/File
import structs/ArrayList

import compilers/AbstractCompiler
import PathList

BuildParams: class {
	compiler: AbstractCompiler = null
	
	// distLocation: File = DistLocator locate()
	// sdkLocation: File = SdkLocator locate()
	
	sourcePath: PathList = PathList new()
	libPath: PathList = PathList new()
	incPath: PathList = PathList new()
	
	outPath: File = File new("ooc_tmp")
	
	// Path of the text editor to run when an error is encountered in an ooc file 
	editor: String = ""
	
	// Remove the ooc_tmp/ directory after the C compiler has finished
	clean: Bool = true
	
	// Add debug info to the generated C files (e.g. -g switch for gcc)
	debug: Bool = false
	
	// Displays which files it parses, and a few debug infos
	verbose: Bool = false
	
	// More debug messages
	veryVerbose: Bool = false
	
	// Displays [ OK ] or [FAIL] at the end of the compilation
	shout: Bool = false
	
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
	
	// maximum number of rounds the {@link Tinkerer} will do before blowing up.
	blowup: Int = 256
	
	dynamicLibs := ArrayList<String> new()
}