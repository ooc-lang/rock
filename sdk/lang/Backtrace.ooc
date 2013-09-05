
// sdk
import os/[Env, Dynlib, ShellUtils]
import io/[File, StringReader]
import text/StringTokenizer
import structs/[ArrayList, List]

// sdk internals
import lang/internals/mangling

// fallback for linux/apple if backtrace-universal isn't present
version ((linux || apple) && !android) {
    include execinfo

    backtrace: extern func (array: Void**, size: Int) -> Int
    backtraceSymbols: extern(backtrace_symbols) func (array: const Void**, size: Int) -> Char**
    backtraceSymbolsFd: extern(backtrace_symbols_fd) func (array: const Void**, size: Int, fd: Int)
}

BacktraceHandler: class {
    
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

    // fancy?
    fancy? := true

    // funcs
    registerCallback, capture: Pointer

    /* public interface */

    captureBacktrace: func -> String {
        if (lib) {
            // use backtrace-universal, best one!
            f := (capture, null) as Func -> CString
            return _format(f() toString())
        } else {
            // fall back on execinfo? still informative
            version (linux || apple) {
                MAX_SIZE := 128
                frames := gc_malloc(MAX_SIZE * Pointer size)
                backtrace(frames, MAX_SIZE)
                cs := backtraceSymbols(frames, MAX_SIZE)
                return cs toString()
            }

            // no such luck, use a debugger :(
            return ""
        }
    }

    /* private stuff */

    init: func {
        if (Env get("NO_FANCY_BACKTRACE")) {
            fancy? = false
            return
        }

        // try to load it from the system's search path
        // includes the current directory on Windows
        lib = Dynlib load("backtrace")

        if (!lib) {
            // try to load it from the current directory?
            // makes the magic work on Linux
            lib = Dynlib load("./backtrace")
        }

        if (!lib) {
            // try to find in rock's path, if rock is there.
            rockPath := ShellUtils findExecutable("rock")
            if (rockPath) {
                binPath := rockPath getParent()
                path := File join(binPath, "backtrace")
                lib = Dynlib load(path)
            }
        }

        if (lib) {
            _initFuncs()

            // get rid of rock's built-in stuff
            Env set("FANCY_BACKTRACE", "1")
        } else {
            // couldn't load :(
            fancy? = false
        }
    }

    _initFuncs: func {
        if (!lib) return

        registerCallback = lib symbol("backtrace_register_callback")
        if (!registerCallback) {
            stderr write("Couldn't get registerCallback symbol!\n")
            return
        }

        capture = lib symbol("backtrace_capture")
        if (!capture) {
            stderr write("Couldn't get capture symbol!\n")
            return
        }

        _registerCallback(|ctrace|
            stderr write(_format(ctrace toString()))
        )
    }

    _registerCallback: func (callback: Func(CString)) {
        if (!lib) return

        f := (registerCallback, null) as Func (Pointer, Pointer)
        c := callback as Closure
        f(c thunk, c context)
    }

    _format: func (trace: String) -> String {
        buffer := Buffer new()

        if (Env get("RAW_BACKTRACE")) {
            buffer append("[original backtrace]\n")
            buffer append(trace). append('\n')
            return buffer toString()
        }

        buffer append("[fancy backtrace]\n")
        lines := trace split('\n')

        frameno := 0
        elements := ArrayList<TraceElement> new()

        for (l in lines) {
            tokens := l split('|') map(|x| x trim())

            if (tokens size <= 4) {
                if (tokens size >= 2) {
                    binary := tokens[0]
                    file := "(from %s)" format(binary)
                    elements add(TraceElement new(frameno, tokens[2], "", file))
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

    init: func (=frameno, =symbol, =package, =file) {
    }

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

