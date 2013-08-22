import ../Thread
import native/win32/[types, errors]

version(windows) {

    /**
     * Win32 implementation of threads.
     *
     * :author: Amos Wenger (nddrylliog)
     */
    ThreadWin32: class extends Thread {

        handle: Handle
        threadID: ULong

        init: func ~win (=_code) {}

        start: func -> Bool {
            handle = CreateThread(
                null,                    // default security attributes
                0,                       // use default stack size
                _code as Closure thunk,  // thread function name
                _code as Closure context,// argument to thread function
                0,                       // use default creation flags
                threadID&)               // returns the thread identifier

            handle != INVALID_HANDLE_VALUE
        }

        wait: func -> Bool {
            result := WaitForSingleObject(handle, INFINITE)
            result == WAIT_OBJECT_0
        }

        wait: func ~timed (seconds: Double) -> Bool {
            Exception new(This, "wait~timed: stub") throw()
            false
        }

        isAlive?: func -> Bool {
            result := WaitForSingleObject(handle, 0)

            // if it's equal, it has terminated, otherwise, it's still alive
            result != WAIT_OBJECT_0
        }

        _currentThread: static func -> This {
            thread := This new(func {})
            thread handle = GetCurrentThread()
            thread
        }

        _yield: static func -> Bool {
            // I secretly curse whoever thought of this function name
            SwitchToThread()
        }

    }

    /* C interface */

    // Note that for the GC and Win32 threads to play well, the GC has to be
    // linked dynamically, and not statically. Use `--gc=dynamic` to achieve
    // that, and make sure you have a copy of libgc.dll.a in your libpath

    include windows

    // Was GC_CreateThread, but it has been removed in recent versions of Boehm
    CreateThread: extern func (...) -> Handle
    GetCurrentThread: extern func -> Handle
    WaitForSingleObject: extern func (...) -> Long
    SwitchToThread: extern func

    INFINITE: extern Long
    WAIT_OBJECT_0: extern Long

}
