import threading/[Runnable, Thread]
 
MyRunnable: class extends Runnable {
	id: Int

	init: func (=id) {}

    run: func {
		for(i in 0..5) {
	        // do work here
	        printf("(%d) being ran!\n", id)
        }
    }
}


main: func {

	t := Thread new(MyRunnable new())
	t start()
 
	// Also allow creating threads from closures maybe...
	//t2 := Thread new(func { /* do work */ })
	//t2 start()
	
}