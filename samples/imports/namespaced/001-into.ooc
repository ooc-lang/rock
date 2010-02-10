import threading/Thread into threading
import threading/Runnable

MyRunnable: class extends Runnable {
    
    run: func {
        printf("Huhu.\n")
    }
    
}

main: func {
    t := threading Thread new(MyRunnable new())
    t start()
    t wait()
}
