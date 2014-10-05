import native/[CoroUnix, CoroWin32]

/**
 * Portable ucontext/fiber-based coroutines implementation for cooperative multitasking.
 *
 * Based on the work of:
 *  - Steve Dekorte (libcoroutine - http://github.com/stevedekorte/coroutine)
 *  - Russ Cox (libcoroutine OSX10.6 fixes)
 *  - Edgar Toernig (Minimalistic cooperative multitasking - http://www.goron.de/~froese/)
 */
Coro: abstract class {
    // 128k stack is enough room for quite a few function calls
    DEFAULT_STACK_SIZE := static 128 * 1_024

    isMain := false

    new: static func -> This {
        version(unix || apple) {
            return CoroUnix new() as This
        }
        version(windows) {
            return CoroWin32 new() as This
        }
        raise("os/Coro is unsupported on your platform!")
        null
    }

    /// Marks that this Coro is a main coro (cannot yield)
    initializeMainCoro: func {
        isMain = true
    }

    /// Starts a child Coro that executes the callback
    startCoro: abstract func(other: This, callback: Func)

    /// Sets up a child Coro
    setup: abstract func(other: This, callback: Func)

    /// Switches execution to another Coro
    switchTo: abstract func(next: This)

    /// Yields execution to the Coro that spawned this
    yield: abstract func

    /// Frees non-GC memory that the Coro may have allocated (e.g. stack memory)
    free: abstract func
}
