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
     *
     * :author: Amos Wenger (nddrylliog)
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

}