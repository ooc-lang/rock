import native/[ThreadUnix, ThreadWin32]

Thread: abstract class {

    closure: Func

    new: static func ~fromRunnable (.closure) -> This {

        version (unix || apple) {
            return ThreadUnix new(closure) as This
        }
        version (windows) {
            return ThreadWin32 new(closure) as This
        }

        Exception new(This, "Unsupported platform!\n") throw()
        null

    }

    start: abstract func -> Int

    wait: abstract func -> Int

}
