
// sdk
import threading/Thread
import structs/[Stack, LinkedList]
import lang/Backtrace

include setjmp, assert, errno

version(windows) {
    include windows

    DebugBreak: extern func
    RaiseException: extern func (ULong, ULong, ULong, Pointer)
    IsDebuggerPresent: extern func -> Pointer
}

JmpBuf: cover from jmp_buf {
    setJmp: extern(setjmp) func -> Int
    longJmp: extern(longjmp) func (value: Int)
}

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

version(windows) {
    import native/win32/[types, errors]

    getOSErrorCode: func -> Int {
        GetLastError()
    }

    getOSError: func -> String {
        GetWindowsErrorMessage(GetLastError())
        
    }
} else {
    errno: extern Int
    strerror: extern func (Int) -> CString

    getOSErrorCode: func -> Int {
        errno
    }

    getOSError: func -> String {
        x := strerror(errno)
        return (x != null) ? x toString() : ""
    }
}

raise: func(msg: String) {
    Exception new(msg) throw()
}

raise: func ~withClass(clazz: Class, msg: String) {
    Exception new(clazz, msg) throw()
}

/**
 * Base class for all exceptions that can be thrown
 */
Exception: class {
    backtraces: LinkedList<Backtrace> = LinkedList<Backtrace> new()

    addBacktrace: func {
        bt := BacktraceHandler get() backtrace()
        if (bt) {
            backtraces add(bt)
        }
    }

    printBacktrace: func {
        h := BacktraceHandler get()
        for (backtrace in backtraces) {
            stderr write(h backtraceSymbols(backtrace))
        }
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
    init: func  (=origin, =message) {
    }

    /**
     * Create an exception
     *
     * @param message A short text explaning why the exception was thrown
     */
    init: func ~noOrigin (=message) {
        init(null, message)
    }


    /**
     * @return the exception's message, nicely formatted
     */
    formatMessage: func -> String {
        if(origin)
            "[%s in %s]: %s\n" format(class name toCString(), origin name toCString(), message ? message toCString() : "<no message>" toCString())
        else
            "[%s]: %s\n" format(class name toCString(), message ? message toCString() : "<no message>" toCString())
    }

    /**
     * Print this exception, with its origin, if specified, and its message
     */
    print: func {
        printMessage()
        printBacktrace()
    }

    /**
     * Print just the message
     */
    printMessage: func {
        fprintf(stderr, "%s", formatMessage() toCString())
    }

    /**
     * Throw this exception
     */
    throw: func {
        _setException(this)
        addBacktrace()
        if(!_hasStackFrame()) {
            version (windows) {
                if (IsDebuggerPresent()) {
                    // trigger a break point here, debugger will like that!
                    printMessage()
                    DebugBreak()
                } else {
                    // print the backtrace ourselves
                    print()
                }
                exit(1)
            }
            version (!windows) {
                printMessage()
                abort()
            }
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

    getCurrentBacktrace: static func -> String {
        h := BacktraceHandler get()
        bt := h backtrace()
        if (bt) {
            return h backtraceSymbols(bt)
        }
        ""
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

/* -------- Signal / exception catching ---------- */

version ((linux || apple) && !android) {
    _signalHandler: func (sig: Int) {
        message := match sig {
            case SIGHUP   => "(SIGHUP ) terminal line hangup"
            case SIGINT   => "(SIGINT ) interrupt program"
            case SIGILL   => "(SIGILL ) illegal instruction"
            case SIGTRAP  => "(SIGTRAP) trace trap"
            case SIGABRT  => "(SIGABRT) abort program"
            case SIGFPE   => "(SIGFPE ) floating point exception"
            case SIGBUS   => "(SIGBUS ) bus error"
            case SIGSEGV  => "(SIGSEGV) segmentation fault"
            case SIGSYS   => "(SIGSYS ) non-existent system call invoked"
            case SIGPIPE  => "(SIGPIPE) write on a pipe with no reader"
            case SIGALRM  => "(SIGALRM) real-time timer expired"
            case SIGTERM  => "(SIGTERM) software termination signal"
        }

        stderr write(message). write('\n')

        // try to display a stack trace.
        stderr write(Exception getCurrentBacktrace())

        exit(sig)
    }
}

_setupHandlers: func {
    version ((linux || apple) && !android) {
        signal(SIGHUP,  _signalHandler)
        signal(SIGINT,  _signalHandler)
        signal(SIGILL,  _signalHandler)
        signal(SIGTRAP, _signalHandler)
        signal(SIGABRT, _signalHandler)
        signal(SIGFPE,  _signalHandler)
        signal(SIGBUS,  _signalHandler)
        signal(SIGSEGV, _signalHandler)
        signal(SIGSYS,  _signalHandler)
        signal(SIGPIPE, _signalHandler)
        signal(SIGALRM, _signalHandler)
        signal(SIGTERM, _signalHandler)
    }
}

_setupHandlers()

/* ------ C interface ------ */

include stdlib

/* stdlib.h -
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

version ((linux || apple) && !android) {

    include signal

    /* signal.h -
     *
     * This signal() facility is a simplified interface to the more general
     * sigaction(2) facility.  Signals allow the manipulation of a process from
     * outside its domain, as well as allowing the process to manipulate itself
     * or copies of itself (children).
     * 
     * There are two general types of signals: those that cause termination of
     * a process and those that do not.  Signals which cause termination of a
     * program might result from an irrecoverable error or might be the result
     * of a user at a terminal typing the `interrupt' character.
     *
     * Signals are used when a process is stopped because it wishes to access
     * its control terminal while in the background (see tty(4)).  Signals are
     * optionally generated when a process resumes after being stopped, when
     * the status of child processes changes, or when input is ready at the
     * control terminal.
     *
     * Most signals result in the termination of the process receiving them, if
     * no action is taken; some signals instead cause the process receiving
     * them to be stopped, or are simply discarded if the process has not
     * requested otherwise.
     * 
     * Except for the SIGKILL and SIGSTOP signals, the signal() function allows
     * for a signal to be caught, to be ignored, or to generate an interrupt.
     */
    signal: extern func (sig: Int, f: Pointer) -> Pointer

    SIGHUP, SIGINT, SIGILL, SIGTRAP, SIGABRT, SIGEMT, SIGFPE, SIGBUS,
    SIGSEGV, SIGSYS, SIGPIPE, SIGALRM, SIGTERM: extern Int

}


