
// sdk
import structs/[ArrayList, List]
import os/Time

version (windows) {
    RaiseException: extern func (ULong, ULong, ULong, Pointer)
}

foo: func {
    // SIGSEGV
    /*
        f: Int* = null
        f@ = 0
    */

    // SIGFPE
    /*
        a := 30
        b := 0
        a /= b
    */

    // Win32 exception
    /*
        RaiseException(0, 0, 0, null)
    */

    // ooc exception
    ///*
        a := ArrayList<Int> new()
        a[0] toString() println()
    //*/

    // no crash? sleep and try again later
    "Sleeping..." println()
    Time sleepSec(2)
}

bar: func {
    foo()
}

main: func {
    app := App new()
    app run()
    0
}

App: class {
    init: func

    run: func {
        version (debug) {
            "Running in debug!" println()
        } else {
            "Running in release!" println()
        }
        
        "> Printing a gratuitious backtrace" println()
        Exception getCurrentBacktrace() println()

        "> Now looping. If it doesn't crash, use Ctrl-C to send SIGINT!" println()

        loop(||
            runToo()
            true
        )
    }

    runToo: func {
        bar()
    }
}

