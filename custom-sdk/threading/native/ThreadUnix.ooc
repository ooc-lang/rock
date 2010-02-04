import ../Thread
include pthread

//version(linux) {

PThread: cover from pthread_t

ThreadUnix: class extends Thread {

	init: func ~unix (=runnable) {}

	start: func {
		// whadoIdonow?
	}

}

//}