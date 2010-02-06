import threading/[Runnable, Thread], os/Time

include stdlib
usleep: extern func (Int)

MyRunnable: class extends Runnable {

    id: Int
    init: func ~id (=id) {}

    run: func {
        stdout: extern FILE*
        for(i in 0..10) {
            printf("%d, ", id)
            fflush(stdout)
            Time sleepMilli(rand() % 2000)
            //usleep(rand() % 1000000)
        }
    }

}


main: func {


    //for(i in 0..3) {
        //t := Thread new(MyRunnable new())
        //t start()
        //t wait()
    //}

    t1 := Thread new(MyRunnable new(1))
    t2 := Thread new(MyRunnable new(2))
    t3 := Thread new(MyRunnable new(3))

    t1 start()
    t2 start()
    t3 start()

    t1 wait()
    t2 wait()
    t3 wait()

    printf("\n")

    // Also allow creating threads from closures maybe...
    //t2 := Thread new(func { /* do work */ })
    //t2 start()

}