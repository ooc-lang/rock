import threading/Thread, structs/Stack

include setjmp

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
    exceptionStack hasValue?() && exceptionStack get() as Stack<StackFrame> size() > 0
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
                "[backtrace] " print()
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
    format: func -> String {
        if(origin)
            "[%s in %s]: %s" format(class name, origin name, message)
        else
            "[%s]: %s" format(class name, message)
    }

    /**
     * Print this exception, with its origin, if specified, and its message
     */
    print: func {
        fprintf(stderr, "%s\n", format())
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

