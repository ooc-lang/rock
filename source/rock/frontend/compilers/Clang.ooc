import Gcc

/**
 * Clang (C-language, LLVM-based) Compiler
 */
Clang: class extends Gcc {
    init: func ~withClang(){
        super("clang")
    }

    clone: func() -> This {
        return Clang new()
    }
}
