import Gcc

/**
 * Intel C++ Compiler
 * 
 * @author Amos Wenger
 */
Icc: class extends Gcc {
    init: func ~withIcc(){
        super("icc")
    }

    reset: func() {
        command clear()
        command add(executablePath)
    }

    clone: func() -> This {
        return Icc new()
    }
}
