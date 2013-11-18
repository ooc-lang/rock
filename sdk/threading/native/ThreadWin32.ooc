import ../Thread
import native/win32/[types, errors]

version(windows) {

    /**
     * Win32 implementation of threads.
     */
    ThreadWin32: class extends Thread {

        handle: Handle
        threadID: UInt

        init: func ~win (=_code) {}

        start: func -> Bool {
            handle = _beginthreadex(
                null,                    // default security attributes
                0,                       // default stack size
                _code as Closure thunk,  // thread start address
                _code as Closure context,// argument to thread function
                0,                       // start thread as soon as it is created
                threadID&) as Handle     // returns the thread identifier

            handle != INVALID_HANDLE_VALUE
        }

        wait: func -> Bool {
            result := WaitForSingleObject(handle, INFINITE)
            result == WAIT_OBJECT_0
        }

        wait: func ~timed (seconds: Double) -> Bool {
            millis := (seconds * 1000.0 + 0.5) as Long
            result := WaitForSingleObject(handle, millis)

            match result {
              case WAIT_TIMEOUT =>
                false // still running
              case WAIT_OBJECT_0 =>
                true // has exited!
              case =>
                // couldn't wait
                Exception new(This, "wait~timed failed with %ld" format(result as Long)) throw()
                false
            }
        }

        alive?: func -> Bool {
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

    include windows

    // CreateThread causes memory leaks, see:
    // http://stackoverflow.com/questions/331536/, and
    // http://support.microsoft.com/kb/104641/en-us
    // CreateThread: extern func (...) -> Handle

    version (gc) {
      // Use Boehm-provided replacement for _beginthreadex
      _beginthreadex: extern(GC_beginthreadex) func (security: Pointer, stackSize: UInt, startAddress: Pointer, arglist: Pointer, initflag: UInt, thrdaddr: UInt*) -> Handle
    }

    version (!gc) {
      _beginthreadex: extern func (security: Pointer, stackSize: UInt, startAddress: Pointer, arglist: Pointer, initflag: UInt, thrdaddr: UInt*) -> Handle
    }

    GetCurrentThread: extern func -> Handle
    WaitForSingleObject: extern func (...) -> Long
    SwitchToThread: extern func -> Bool

    INFINITE: extern Long
    WAIT_OBJECT_0: extern Long
    WAIT_TIMEOUT: extern Long

}
