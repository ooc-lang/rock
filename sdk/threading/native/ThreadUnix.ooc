import ../Thread
include pthread, unistd

version(unix || apple) {

    /* covers & extern functions */
    PThread: cover from pthread_t
    
    pthread_create: extern func (PThread*, Pointer, Func(Pointer) -> Pointer, Pointer) -> Int
    pthread_join:   extern func (thread: PThread, retval: Pointer*) -> Int

    /**
     * pthreads implementation of threads.
     * 
     * :author: Amos Wenger (nddrylliog)
     */
    ThreadUnix: class extends Thread {

        pthread: PThread

        init: func ~unix (=_code) {}

        start: func -> Int {
            return pthread_create(pthread&, null, _code as Func(Pointer) -> Pointer, null)
        }

        wait: func -> Int {
            return pthread_join(pthread, null)
        }

    }

}
