import ../Thread
import native/win32/[types, errors]

version(windows) {

    include windows

    /* covers & extern functions */
    // this used to be GC_CreateThread, but as it turns out, it doesn't 
    // work with recent versions of the gc, and it was redirected to the Win32
    // API anyway :)
    CreateThread: extern func (...) -> Handle
    GetCurrentThread: extern func -> Handle
    WaitForSingleObject: extern func (...) -> Long // laziness
    INFINITE: extern Long
    WAIT_OBJECT_0: extern Long

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
            Exception new(This, "yield: stub") throw()
            false
        }

    }

}
