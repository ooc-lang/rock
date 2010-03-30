import ../[Thread, Runnable]
import native/win32/[types, errors]

version(windows) {

include windows

Handle: cover from HANDLE
INVALID_HANDLE_VALUE: extern Handle
CreateThread: extern func (...) -> Handle
WaitForSingleObject: extern func (...) -> Long // laziness
INFINITE: extern Long
WAIT_OBJECT_0: extern Long

ThreadWin32: class extends Thread {

    handle: Handle
    threadID: Long

    init: func ~win (=runnable) {}

    start: func -> Int {
        handle = CreateThread(
            null,                    // default security attributes
            0,                       // use default stack size
            Runnable run as Pointer, // thread function name
            runnable,                // argument to thread function
            0,                       // use default creation flags
            threadID&)               // returns the thread identifier
        return (handle == INVALID_HANDLE_VALUE ? -1 : 0)
    }

    wait: func -> Int {
        WaitForSingleObject(handle, INFINITE) == WAIT_OBJECT_0 ? 0 : -1
    }

}

}