import structs/HashMap
import ../Thread, ThreadWin32
include unistd

version(windows) {
    include windows

    GetCurrentThreadId: extern func -> Long // TODO: also laziness.
     
    ThreadLocalWin32: class <T> extends ThreadLocal<T> {
        values := HashMap<Long, T> new()
        valuesMutex := Mutex new()

        init: func ~windows {
        
        }
        
        set: func (value: T) {
            valuesMutex lock()
            values put(GetCurrentThreadId(), value)
            valuesMutex unlock()    
        }

        get: func -> T {
            valuesMutex lock()
            value := values get(GetCurrentThreadId())
            valuesMutex unlock()
            value
        }

        hasValue?: func -> Bool {
            valuesMutex lock()
            has := values contains?(GetCurrentThreadId())
            valuesMutex unlock()
            has
        }
    }
}

