import structs/HashMap
import ../Thread, ThreadUnix
include pthread, unistd

version(unix || apple) {
    Key: cover from pthread_key_t

    pthread_self: extern func -> PThread
     
    // TODO: Please make this store pointers to generic values, not generic values.
    ThreadLocalUnix: class <T> extends ThreadLocal<T> {
        values := HashMap<PThread, T> new()
        valuesMutex := Mutex new()

        init: func ~unix {
        
        }
        
        set: func (value: T) {
            valuesMutex lock()
            values put(pthread_self(), value)
            valuesMutex unlock()    
        }

        get: func -> T {
            valuesMutex lock()
            value := values get(pthread_self())
            valuesMutex unlock()
            value
        }

        hasValue?: func -> Bool {
            valuesMutex lock()
            has := values contains?(pthread_self())
            valuesMutex unlock()
            has
        }
    }
}
