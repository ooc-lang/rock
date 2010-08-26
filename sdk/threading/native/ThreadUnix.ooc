import ../Thread
include unistd

version(unix || apple) {
    include pthread

    /* covers & extern functions */
    PThread: cover from pthread_t

    version(gc) {
        pthread_create: extern(GC_pthread_create) func (PThread*, Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern(GC_pthread_join)   func (thread: PThread, retval: Pointer*) -> Int
    }
    version (!gc) {
        pthread_create: extern func (PThread*, Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern func (thread: PThread, retval: Pointer*) -> Int
    }

    /**
     * pthreads implementation of threads.
     *
     * :author: Amos Wenger (nddrylliog)
     */
    ThreadUnix: class extends Thread {

        pthread: PThread

        init: func ~unix (=_code) {}

        start: func -> Int {
            return pthread_create(pthread&, null, _code as Closure thunk, _code as Closure context)
        }

        wait: func -> Int {
            return pthread_join(pthread, null)
        }

    }

}
