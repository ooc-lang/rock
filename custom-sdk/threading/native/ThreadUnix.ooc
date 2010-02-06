//import ../[Thread, Runnable]
//include pthread, unistd

//version(linux) {

/* covers & extern functions */

/*
PThread: cover from pthread_t
pthread_create: extern func (...) -> Int
pthread_join:   extern func (...) -> Int

ThreadUnix: class extends Thread {

    pthread: PThread

    init: func ~unix (=runnable) {}

    start: func -> Int {
        // Feinte du loup des bois. We pass a pointer to the runnable
        // to pthread_create so that it corresponds to the 'this' argument
        // of our member method. Easy enough, huh ?
        return pthread_create(pthread&, null, Runnable run as Pointer, runnable)
    }

    wait: func -> Int {
        return pthread_join(pthread, null)
    }

}
*/

//}