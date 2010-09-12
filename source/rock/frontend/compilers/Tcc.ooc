import Gcc

/**
 * TinyCC - originally by Fabrice Bellard
 *
 * @author Amos Wenger
 */
Tcc: class extends Gcc {
    init: func~withTcc(){
        super("tcc")
    }

    reset: func() {
        command clear()
        command add(executablePath)
    }

    supportsDeclInFor: func() -> Bool {
        return false
    }

    supportsVLAs: func() -> Bool {
        return false
    }

    clone: func() -> This {
        return Tcc new()
    }
}