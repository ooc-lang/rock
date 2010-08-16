import structs/HashMap
import ../Thread
include pthread, unistd

version(unix || apple) {
    Key: cover from pthread_key_t
     
    pthread_key_create: extern func (key: Key*, destructor: Pointer)-> Int // TODO: actually it's a Func (Pointer).
    pthread_setspecific: extern func (key: Key, value: Pointer) -> Int
    pthread_getspecific: extern func(key: Key) -> Pointer
    
    gc_malloc_uncollectable: extern(GC_MALLOC_UNCOLLECTABLE) func (SizeT) -> Pointer

    // TODO: Please make this store pointers to generic values, not generic values.
    ThreadLocalUnix: class <T> extends ThreadLocal<T> {
        key: Key
        containers := HashMap<Pointer, T> new()
        containersMutex := Mutex new()

        init: func ~unix {
            pthread_key_create(key&, null) // TODO: error checking
        }

        generateIndex: func -> Pointer {
            gc_malloc(Octet size)
        }

        setContainer: func (index: Pointer, value: T) {
            containersMutex lock()
            containers put(index, value)
            containersMutex unlock()
        }

        set: func (value: T) {
            index := pthread_getspecific(key)
            if(index == null)
                index = generateIndex()
            setContainer(index, value)
            pthread_setspecific(key, index)
        }

        get: func -> T {
            index := pthread_getspecific(key)
            containersMutex lock()
            value := containers get(index)
            containersMutex unlock()
            value
        }

        hasValue: func -> Bool {
            pthread_getspecific(key) != null
        }
    }
}
