import Runnable, native/ThreadUnix

Thread: class {

	runnable: Runnable

    new: static func ~fromRunnable (=runnable) -> This {
    
		//version (unix || apple) {
			return ThreadUnix new(runnable)
		//}
		//version (windows) {
		//  return ThreadWin32 new(runnable)
		//}

		Exception new(This, "Unsupported platform!\n") throw()
		null
		
    }

    start: abstract func {}
    
}
