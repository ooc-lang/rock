import Runnable, native/ThreadUnix

Thread: class {

    runnable: Runnable

    new: static func ~fromRunnable (=runnable) -> This {

        //version (unix || apple) {
        //  return ThreadUnix new(runnable) as This
        //}
        //version (windows) {
            return ThreadWin32 new(runnable) as This
        //}

        Exception new(This, "Unsupported platform!\n") throw()
        null

    }

    start: abstract func -> Int

    wait: abstract func -> Int

}
