import ../Thread
include pthread, unistd

version(unix || apple) {
    Key: cover from pthread_key_t
     
    pthread_key_create: extern func (key: Key*, destructor: Pointer)-> Int // TODO: actually it's a Func (Pointer).
    pthread_setspecific: extern func (key: Key, value: Pointer) -> Int
    pthread_getspecific: extern func(key: Key) -> Pointer

    ThreadLocalUnix: class <T> extends ThreadLocal<T> {
        key: Key

        init: func ~unix {
            pthread_key_create(key&, null) // TODO: error checking
        }

        set: func (value: T) {
            pthread_setspecific(key, value&)
        }

        get: func -> T {
            (pthread_getspecific(key) as T*)@
        }
    }
}
