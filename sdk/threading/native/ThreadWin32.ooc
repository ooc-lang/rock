import ../Thread
import native/win32/[types, errors]

version(windows) {

    include windows

    /* covers & extern functions */
    // this used to be GC_CreateThread, but as it turns out, it doesn't 
    // work with recent versions of the gc, and it was redirected to the Win32
    // API anyway :)
    CreateThread: extern func (...) -> Handle
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
        threadID: Long

        init: func ~win (=_code) {}

        start: func -> Int {
            handle = CreateThread(
                null,                    // default security attributes
                0,                       // use default stack size
                _code as Closure thunk,  // thread function name
                _code as Closure context,// argument to thread function
                0,                       // use default creation flags
                threadID&)               // returns the thread identifier
            return (handle == INVALID_HANDLE_VALUE ? -1 : 0)
        }

        wait: func -> Int {
            WaitForSingleObject(handle, INFINITE) == WAIT_OBJECT_0 ? 0 : -1
        }

    }

}
