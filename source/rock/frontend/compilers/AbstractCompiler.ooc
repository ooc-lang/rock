AbstractCompiler: abstract class {
	
	/** -o option in gcc */
	setOutputPath: abstract func(path: String)
	
	/** -I option in gcc */
	addIncludePath: abstract func(path: String)
	
	/** -L option in gcc */
	addLibraryPath: abstract func(path: String)
	
	/** -l option in gcc */
	addDynamicLibrary: abstract func(library: String)
	
	/** -c option in gcc */
	setCompileOnly: abstract func()
	
	/** -g option in gcc */
	setDebugEnabled: abstract func()
	
	/** .o file to link with */
	addObjectFile: abstract func(path: String)
	
	/** any compiler-specific option */
	addOption: abstract func(option: String)
	
	/** @return the exit code of the compiler */
	launch: abstract func() -> Int
	
	supportDeclInFor: abstract func() -> Bool
	
	supportVLAs: abstract func() -> Bool
	
	reset: abstract func()
	
	getCommandLine: abstract func() -> String
	
	clone: abstract func() -> This

}
