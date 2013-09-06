import ../Thread
import native/win32/[types, errors]

version(windows) {

    include windows

    /* covers & extern functions */
    CreateMutex: extern func (Pointer, Bool, Pointer) -> Handle
    ReleaseMutex: extern func (Handle)
    CloseHandle: extern func (Handle)

    WaitForSingleObject: extern func (...) -> Long // laziness
    INFINITE: extern Long

    /**
     * Win32 implementation of mutexes.
     */
    MutexWin32: class extends Mutex {

        new: static func -> Mutex {
            mut := CreateMutex (
                null,  // default security attributes
                false, // initially not owned
                null)  // unnamed mutex
            mut as Mutex
        }

    }

    ooc_mutex_lock: inline unmangled func (m: Mutex) {
        WaitForSingleObject(
            m as Handle, // handle to mutex
            INFINITE         // no time-out interval
        )
    }

    ooc_mutex_unlock: inline unmangled func (m: Mutex) {
        ReleaseMutex(m as Handle)
    }

    ooc_mutex_destroy: inline unmangled func (m: Mutex) {
        CloseHandle(m as Handle)
    }

    /**
     * Win32 implementation of recursive mutexes.
     *
     * Apparently, Win32 mutexes are recursive by default, so this is just a
     * copy of `MutexWin32`, which is by
     */
    RecursiveMutexWin32: class extends Mutex {

        new: static func -> RecursiveMutex {
            mut := CreateMutex (
                null,  // default security attributes
                false, // initially not owned
                null)  // unnamed recursive_mutex
            mut as RecursiveMutex
        }

    }

    ooc_recursive_mutex_lock: inline unmangled func (m: RecursiveMutex) {
        WaitForSingleObject(
            m as Handle, // handle to recursive_mutex
            INFINITE         // no time-out interval
        )
    }

    ooc_recursive_mutex_unlock: inline unmangled func (m: RecursiveMutex) {
        ReleaseMutex(m as Handle)
    }

    ooc_recursive_mutex_destroy: inline unmangled func (m: RecursiveMutex) {
        CloseHandle(m as Handle)
    }
}
