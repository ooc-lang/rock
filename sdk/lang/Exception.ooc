include assert
include errno

assert: extern func(Bool)

errno: extern Int
strerror: extern func (Int) -> CString

getOSError: func -> String {
    x := strerror(errno)
    return (x != null) ? String new(x, x length()) : String new()
}

raise: func(msg: String) {
    Exception new(msg) throw()
}

raise: func~withClass(clazz: Class, msg: String) {
    Exception new(clazz, msg) throw()
}

/**
 * Base class for all exceptions that can be thrown
 *
 * @author Amos Wenger (nddrylliog)
 */
Exception: class {

    /** Class which threw the exception. May be null */
    origin: Class

    /** Message associated with this exception. Printed when the exception is thrown. */
    message : String

    /**
     * Create an exception
     *
     * @param origin The class throwing this exception
     * @param message A short text explaning why the exception was thrown
     */
    init: func  (=origin, =message) {}

    /**
     * Create an exception
     *
     * @param message A short text explaning why the exception was thrown
     */
    init: func ~noOrigin (=message) {}


    /**
     * @return the exception's message, nicely formatted
     */
    formatMessage: func -> String {
        if(origin)
            "[%s in %s]: %s\n" format(class name toCString(), origin name toCString(), message toCString())
        else
            "[%s]: %s\n" format(class name toCString(), message toCString())
    }

    /**
     * Print this exception, with its origin, if specified, and its message
     */
    print: func {
        fprintf(stderr, "%s", formatMessage() toCString())
    }

    /**
     * Throw this exception
     */
    throw: inline final func {
        print()
        abort()
    }

}

OSException: class extends Exception {
   init: func (=message) {
        init()
    }
    init: func ~noOrigin {
        x := getOSError()
        if ((message != null) && (!message empty?())) {
            message append(':')
            message append(x)
        } else message = x
    }
}

OutOfBoundsException: class extends Exception {
    init: func (=origin, accessOffset: SizeT, elementLength: SizeT) {
        init(accessOffset, elementLength)
    }
    init: func ~noOrigin (accessOffset: SizeT, elementLength: SizeT) {
        message = "Trying to access an element at offset %d, but size is only %d!" format(accessOffset,elementLength)
    }
}

OutOfMemoryException: class extends Exception {
    init: func (=origin) {
        init()
    }
    init: func ~noOrigin {
        message = "Failed to allocate more memory!"
    }
}

/* ------ C interfacing ------ */

include stdlib

/** stdlib.h -
 *
 * The  abort() first unblocks the SIGABRT signal, and then raises that
 * signal for the calling process.  This results in the abnormal
 * termination of the process unless the SIGABRT signal is caught
 * and the signal handler does not return (see longjmp(3)).
 *
 * If the abort() function causes process termination, all open streams
 * are closed and flushed.
 *
 * If the SIGABRT signal is ignored, or caught by a handler that returns,
 * the abort() function will still terminate the process.  It does this
 * by restoring the default disposition for SIGABRT and then raising
 * the signal for a second time.
 */
abort: extern func

