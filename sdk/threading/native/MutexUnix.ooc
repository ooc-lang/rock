import ../Thread

version(unix || apple) {

    include pthread | (_XOPEN_SOURCE=500)
    include unistd

    /* covers & extern functions */
    PThreadMutex: cover from pthread_mutex_t
    PThreadMutexAttr: cover from pthread_mutexattr_t

    pthread_mutex_lock   : extern func (PThreadMutex*)
    pthread_mutex_unlock : extern func (PThreadMutex*)
    pthread_mutex_init   : extern func (PThreadMutex*, PThreadMutexAttr*)
    pthread_mutex_destroy: extern func (PThreadMutex*)

    pthread_mutexattr_init: extern func (PThreadMutexAttr*)
    pthread_mutexattr_settype: extern func (PThreadMutexAttr*, Int)

    PTHREAD_MUTEX_RECURSIVE: extern Int

    /**
     * pthreads implementation of mutexes.
     */
    MutexUnix: class extends Mutex {

        new: static func -> Mutex {
            mut := gc_malloc(PThreadMutex size) as PThreadMutex*
            pthread_mutex_init(mut, null)
            mut as Mutex
        }

    }

    ooc_mutex_lock: inline unmangled func (m: Mutex) {
        pthread_mutex_lock(m as PThreadMutex*)
    }

    ooc_mutex_unlock: inline unmangled func (m: Mutex) {
        pthread_mutex_unlock(m as PThreadMutex*)
    }

    ooc_mutex_destroy: inline unmangled func (m: Mutex) {
        pthread_mutex_destroy(m as PThreadMutex*)
    }

    RecursiveMutexUnix: class extends Mutex {

        new: static func -> RecursiveMutex {
            mut := gc_malloc(PThreadMutex size) as PThreadMutex*
        attr: PThreadMutexAttr
        pthread_mutexattr_init(attr&)
        pthread_mutexattr_settype(attr&, PTHREAD_MUTEX_RECURSIVE)
            pthread_mutex_init(mut, attr&)
            mut as RecursiveMutex
        }

    }

    ooc_recursive_mutex_lock: inline unmangled func (m: RecursiveMutex) {
        pthread_mutex_lock(m as PThreadMutex*)
    }

    ooc_recursive_mutex_unlock: inline unmangled func (m: RecursiveMutex) {
        pthread_mutex_unlock(m as PThreadMutex*)
    }

    ooc_recursive_mutex_destroy: inline unmangled func (m: RecursiveMutex) {
        pthread_mutex_destroy(m as PThreadMutex*)
    }


}
