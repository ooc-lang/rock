
// sdk
import os/[Env, Dynlib, ShellUtils]
import io/[File, StringReader]
import text/StringTokenizer
import structs/[ArrayList, List]

// sdk internals
import lang/internals/mangling

BacktraceHandler: class {

    // constants
    BACKTRACE_LENGTH := static 128
    WARNED_ABOUT_FALLBACK := false
    
    // singleton
    instance: static This

    get: static func -> This {
        if (!instance) {
            instance = BacktraceHandler new()
        }
        instance
    }

    // DLL
    lib: Dynlib

    /* dylinb functions */
    fancyBacktrace: Pointer
    fancyBacktraceSymbols: Pointer
    fancyBacktraceWithContext: Pointer // windows-only
    
    /* options */

    // fancy? (use fancy-backtrace)
    fancy? := true

    // raw? (don't format)
    raw? := false

    /* public interface */

    backtrace: func -> Backtrace {
        buffer := gc_malloc(Pointer size * BACKTRACE_LENGTH)

        if (lib) {
            // use fancy-backtrace, best one!
            f := (fancyBacktrace, null) as Func (Pointer*, Int) -> Int
            length := f(buffer, BACKTRACE_LENGTH)
            return Backtrace new(buffer, length)
        } else {
            // fall back on execinfo? still informative
            version (linux || apple) {
                if (!WARNED_ABOUT_FALLBACK) {
                    stderr write("[lang/Backtrace] Falling back on execinfo.. (build extension if you want fancy backtraces)\n")
                    WARNED_ABOUT_FALLBACK = true
                }
                length := backtrace(buffer, BACKTRACE_LENGTH)
                return Backtrace new(buffer, length)
            }

            // no such luck, use a debugger :(
            stderr write("[lang/Backtrace] No backtrace extension nor execinfo - use a debugger!\n")
            return null
        }
    }

    backtraceWithContext: func (contextPtr: Pointer) -> Backtrace {
        version (windows) {
            buffer := gc_malloc(Pointer size * BACKTRACE_LENGTH) as Pointer*
            f := (fancyBacktraceWithContext, null) as Func (Pointer*, Int, Pointer) -> Int
            length := f(buffer, BACKTRACE_LENGTH, contextPtr)
            return Backtrace new(buffer, length)
        }

        return null
    }

    backtraceSymbols: func (trace: Backtrace) -> String {
        lines: CString* = null

        if (lib) {
            // use fancy-backtrace
            f := (fancyBacktraceSymbols, null) as Func (Pointer*, Int) -> CString*
            lines = f(trace buffer, trace length)
            return _format(lines, trace length)
        } else {
            // fall back on execinfo
            version (linux || apple) {
                lines = backtrace_symbols(trace buffer, trace length)

                // nothing to format here, just a dumb platform-specific
                // stack trace :/
                buffer := Buffer new()
                for (i in 0..trace length) {
                    buffer append(lines[i]). append('\n')
                }
                return buffer toString()
            }
        }

        "[no backtrace]"
    }

    /* private stuff */

    init: func {
        if (Env get("NO_FANCY_BACKTRACE")) {
            fancy? = false
            return
        }

        if (Env get("RAW_BACKTRACE")) {
            raw? = true
        }

        // try to load it from the system's search path
        // includes the current directory on Windows
        lib = Dynlib load("fancy_backtrace")

        if (!lib) {
            // try to load it from the current directory?
            // makes the magic work on Linux
            lib = Dynlib load("./fancy_backtrace")
        }

        if (!lib) {
            // try to find in rock's path, if rock is there.
            rockPath := ShellUtils findExecutable("rock")
            if (rockPath) {
                binPath := rockPath getParent()
                path := File join(binPath, "fancy_backtrace")
                lib = Dynlib load(path)
            }
        }

        if (lib) {
            _initFuncs()

            // register exit handler
            atexit(_cleanup_backtrace)
        } else {
            // couldn't load :(
            fancy? = false
        }
    }

    _initFuncs: func {
        if (!lib) return

        _getSymbol(fancyBacktrace&, "fancy_backtrace")
        _getSymbol(fancyBacktraceSymbols&, "fancy_backtrace_symbols")

        version (windows) {
            _getSymbol(fancyBacktraceWithContext&, "fancy_backtrace_with_context")
        }
    }

    _getSymbol: func (target: Pointer@, name: String) {
        target = lib symbol(name)
        if (!target) {
            stderr write("[lang/Backtrace] Couldn't get %s symbol!\n" format(name))
            lib = null
        }
    }

    _format: func (lines: CString*, length: Int) -> String {
        buffer := Buffer new()

        if (raw?) {
            buffer append("[raw backtrace]\n")
            for (i in 0..length) {
                buffer append(lines[i]). append('\n')
            }
            return buffer toString()
        }

        buffer append("[fancy backtrace]\n")

        frameno := 0
        elements := ArrayList<TraceElement> new()

        for (i in 0..length) {
            line := lines[i] toString()
            tokens := line split('|') map(|x| x trim())

            if (tokens size <= 4) {
                if (tokens size >= 2) {
                    binary := tokens[0]
                    file := "(from %s)" format(binary)
                    symbol := tokens[2]
                    if (symbol size >= 30) {
                        symbol = "..." + symbol substring(symbol size - 30)
                    }
                    elements add(TraceElement new(frameno, symbol, "", file))
                }
            } else {
                filename := tokens[3]
                lineno := tokens[4]

                mangled := tokens[2]
                fullSymbol := Demangler demangle(mangled)
                package := "in %s" format(fullSymbol package)
                fullName := "%s()" format(fullSymbol fullName)
                file := "(at %s:%s)" format(filename, lineno)
                elements add(TraceElement new(frameno, fullName, package, file))
            }
            frameno += 1
        }

        maxSymbolSize := 0
        maxPackageSize := 0
        maxFileSize := 0
        for (elem in elements) {
            if (elem symbol size > maxSymbolSize) {
                maxSymbolSize = elem symbol size
            }
            if (elem package size > maxPackageSize) {
                maxPackageSize = elem package size
            }
            if (elem file size > maxFileSize) {
                maxFileSize = elem file size
            }
        }

        for (elem in elements) {
            buffer append("%s  %s  %s  %s\n" format(
                TraceElement pad(elem frameno toString(), 4),
                TraceElement pad(elem symbol, maxSymbolSize),
                TraceElement pad(elem package, maxPackageSize),
                TraceElement pad(elem file, maxFileSize)
            ))
        }
        buffer toString()
    }

}

TraceElement: class {
    frameno: Int
    symbol, package, file: String

    init: func (=frameno, =symbol, =package, =file)

    pad: static func (s: String, length: Int) -> String {
        if (s size < length) {
            b := Buffer new()
            b append(s)
            for (i in (s size)..length) {
                b append(' ')
            }
            return b toString()
        }
        s
    }
}

/**
 * Holds a yet-unformatted backtrace.
 */
Backtrace: class {
    buffer: Pointer*
    length: Int

    init: func(=buffer, =length)
}

/*
 * Called on program exit, frees the library - absolutely necessary
 * on Win32, absolutely useless on other platforms, but doesn't hurt.
 * Sucks in any case.
 */
_cleanup_backtrace: func {
    h := BacktraceHandler get()
    if (h lib) {
        h lib close()
    }
}

/* ------ C interface ------ */

// fallback for linux/apple
version ((linux || apple) && !android) {
    include execinfo

    backtrace: extern func (array: Void**, size: Int) -> Int
    backtrace_symbols: extern func (
        array: Pointer*, size: Int) -> CString*
    backtrace_symbols_fd: extern func (
        array: Pointer*, size: Int, fd: Int)
}

