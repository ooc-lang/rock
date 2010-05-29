import ../Thread
include pthread, unistd

version(unix || apple) {

    /* covers & extern functions */
    PThread: cover from pthread_t
    pthread_create: extern func (...) -> Int
    pthread_join:   extern func (...) -> Int

    ThreadUnix: class extends Thread {

        pthread: PThread

        init: func ~unix (=closure) {}

        start: func -> Int {
            return pthread_create(pthread&, null, closure as Func(Pointer) -> Pointer, null)
        }

        wait: func -> Int {
            return pthread_join(pthread, null)
        }

    }

}
