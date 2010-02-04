import threading/[Runnable, Thread]

include stdlib
sleep: extern func (Int)
 
MyRunnable: class extends Runnable {

	id: Int
	init: func ~id (=id) {}

    run: func {
		for(i in 0..5) {
	        // do work here
	        printf("(%d) being ran!\n", id)
	        //Time sleepSec(1)
	        sleep(1)
        }
    }
    
}


main: func {

	//for(i in 0..3) {
		t := Thread new(MyRunnable new())
		t start()
	//}
 
	// Also allow creating threads from closures maybe...
	//t2 := Thread new(func { /* do work */ })
	//t2 start()
	
}