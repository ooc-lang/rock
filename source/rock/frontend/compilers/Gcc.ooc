import BaseCompiler

/**
 * Gnu Compilers Collection 
 * 
 * @author Amos Wenger
 */
Gcc: class extends BaseCompiler {
    
    init: func~withGcc {
        super("gcc")
    }
    
    init: func~withExecutableName (executableName: String) {
        super(executableName)
    }
    
    addDynamicLibrary: func (library: String) {
        command add("-l" + library)
    }

    addIncludePath: func (path: String) {
        command add("-I" + path)
    }

    addLibraryPath: func (path: String) {
        command add("-L"+path)
    }

    addObjectFile: func (file: String) {
        command add(file)
    }

    addOption: func (option: String) {
        command add(option)
    }

    setOutputPath: func (path: String) {
        command add("-o")
        command add(path)
    }

    setCompileOnly: func {
        command add("-c")
    }

    setDebugEnabled: func {
        command add("-g")
    }
    
    defineSymbol: func (symbol: String) {
        command add("-D" + symbol)
    }
    
    reset: func() {
        super()
        command add("-O2")
        command add("-std=gnu99")
        command add("-Wall")
    }

    supportsDeclInFor: func() -> Bool {
        return true
    }

    supportsVLAs: func() -> Bool {
        return true
    }
    
    clone: func() -> This {
        return Gcc new()
    }
    
}
