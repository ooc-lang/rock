/*
  For bestest backtraces, pass `-g +-rdynamic` to rock when compiling.

  gcc's documentation for -rdynamic:
        -rdynamic
           Pass the flag -export-dynamic to the ELF linker, on targets that
           support it. This instructs the linker to add all symbols, not only
           used ones, to the dynamic symbol table. This option is needed for
           some uses of "dlopen" or to allow obtaining backtraces from within a
           program.

 */
import threading/Thread, structs/Stack

include setjmp, assert, errno

version(linux) {
    include execinfo

    backtrace: extern func (array: Void**, size: Int) -> Int
    backtraceSymbols: extern(backtrace_symbols) func (array: const Void**, size: Int) -> Char**
    backtraceSymbolsFd: extern(backtrace_symbols_fd) func (array: const Void**, size: Int, fd: Int)
}

JmpBuf: cover from jmp_buf {
    setJmp: extern(setjmp) func -> Int
    longJmp: extern(longjmp) func (value: Int)
}

BACKTRACE_LENGTH := 20

_StackFrame: cover {
    buf: JmpBuf
}

StackFrame: cover from _StackFrame* {
    new: static func -> This {
        gc_malloc(_StackFrame size)
    }
}

exceptionStack := ThreadLocal<Stack<StackFrame>> new()

_exception := ThreadLocal<Exception> new()
_EXCEPTION: Int = 1

_pushStackFrame: inline func -> StackFrame {
    stack: Stack<StackFrame>
    if(!exceptionStack hasValue?()) {
        stack = Stack<StackFrame> new()
        exceptionStack set(stack)
    } else {
        stack = exceptionStack get()
    }
    buf := StackFrame new()
    stack push(buf)
    buf
}

_setException: inline func (e: Exception) {
    _exception set(e)
}

_getException: inline func -> Exception {
    _exception get()
}

_popStackFrame: inline func -> StackFrame {
    exceptionStack get() as Stack<StackFrame> pop() as StackFrame
}

_hasStackFrame: inline func -> Bool {
    exceptionStack hasValue?() && exceptionStack get() as Stack<StackFrame> size > 0
}

assert: extern func(Bool)

errno: extern Int
strerror: extern func (Int) -> CString

getOSError: func -> String {
    x := strerror(errno)
    return (x != null) ? x toString() : ""
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
    backtraceBuffer: Pointer*
    backtraceLength: Int

    setBacktrace: func {
        version(linux) {
            backtraceBuffer = gc_malloc(Pointer size * BACKTRACE_LENGTH)
            backtraceLength = backtrace(backtraceBuffer, BACKTRACE_LENGTH)
        }
        // TODO: other platforms
    }

    printBacktrace: func {
        version(linux) {
            if(backtraceBuffer != null) {
                fprintf(stderr, "[backtrace] ")
                backtraceSymbolsFd(backtraceBuffer, backtraceLength, 2) // hell yeah stderr fd.
            }
        }
        // TODO: other platforms
    }

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
        printBacktrace()
    }

    /**
     * Throw this exception
     */
    throw: func {
        _setException(this)
        setBacktrace()
        if(!_hasStackFrame()) {
            print()
            abort()
        } else {
            frame := _popStackFrame()
            frame@ buf longJmp(_EXCEPTION)
        }
    }

    /**
     * Rethrow this exception.
     */
    rethrow: func {
        throw()
    }
}

OSException: class extends Exception {
   init: func (=message) {
        init()
    }
    init: func ~noOrigin {
        x := getOSError()
        if ((message != null) && (!message empty?())) {
            message = message append(':') append(x)
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

