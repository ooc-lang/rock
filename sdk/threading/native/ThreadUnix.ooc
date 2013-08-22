import ../Thread
include unistd

version(unix || apple) {

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

        alive?: func -> Bool {
            pthread_kill(pthread, 0) == 0
        }

        _currentThread: static func -> This {
            thread := This new(func {})
            thread pthread = pthread_self()
            thread
        }

        _yield: static func -> Bool {
            // pthread_yield is non-standard, use sched_yield instead
            // as a bonus, this works on OSX too.
            result := sched_yield()
            result == 0
        }

    }

    /* C interface */
    include pthread
    include sched

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
    pthread_self: extern func -> PThread
    sched_yield: extern func -> Int
}
