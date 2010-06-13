import ../Thread
include pthread, unistd

version(unix || apple) {

    /* covers & extern functions */
    PThreadMutex: cover from pthread_mutex_t
    PThreadMutexAttr: cover from pthread_mutexattr_t

    pthread_mutex_lock   : extern func (PThreadMutex*)
    pthread_mutex_unlock : extern func (PThreadMutex*)
    pthread_mutex_init   : extern func (PThreadMutex*, PThreadMutexAttr*)
    pthread_mutex_destroy: extern func (PThreadMutex*)

    __SIZEOF_PTHREAD_MUTEX_T: extern SizeT

    /**
     * pthreads implementation of mutexes.
     *
     * :author: Amos Wenger (nddrylliog)
     */
    MutexUnix: class extends Mutex {

        new: static func -> Mutex {
            mut := gc_malloc(__SIZEOF_PTHREAD_MUTEX_T) as PThreadMutex*
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

}