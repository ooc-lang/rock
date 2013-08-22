import ../Thread
include unistd

version(unix || apple) {
    include pthread

    /* covers & extern functions */
    PThread: cover from pthread_t

    version(gc) {
        pthread_create: extern(GC_pthread_create) func (threadPtr: PThread*, attrPtr: Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern(GC_pthread_join)   func (thread: PThread, retval: Pointer*) -> Int
    }
    version (!gc) {
        pthread_create: extern func (threadPtr: PThread*, attrPtr: Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern func (thread: PThread, retval: Pointer*) -> Int
    }
    pthread_kill: extern func (thread: PThread, signal: Int) -> Int

    /**
     * pthreads implementation of threads.
     *
     * :author: Amos Wenger (nddrylliog)
     */
    ThreadUnix: class extends Thread {

        pthread: PThread

        init: func ~unix (=_code) {}

        start: func -> Bool {
            result := pthread_create(pthread&, null, _code as Closure thunk, _code as Closure context)
            result == 0
        }

        wait: func -> Bool {
            result := pthread_join(pthread, null)
            result == 0
        }

        wait: func ~timed (seconds: Double) -> Bool {
            Exception new(This, "wait~timed: stub") throw()
            false
        }

        isAlive?: func -> Bool {
            pthread_kill(pthread, 0) == 0
        }

        _currentThread: static func -> This {
            Exception new(This, "currentThread: stub") throw()
            null
        }

        _yield: static func -> Bool {
            Exception new(This, "yield: stub") throw()
            false
        }

    }

}
