import ../Coro

version(windows) {

include windows

CoroWin32: class extends Coro {

    fiber: Pointer
    parent: Pointer

    init: func

    initializeMainCoro: func {
        isMain = true

        if(GetCurrentFiber() == 0x1e00 as Pointer) {
            ConvertThreadToFiber(this)
        }

        fiber = GetCurrentFiber()
    }

    startCoro: final func(other: Coro, callback: Func) {
        other setup(this, ||
            callback()
            raise("Scheduler error: returned from coro start function")
            exit(-1)
        )
        switchTo(other)
        other free()
    }

    switchTo: final func(next: Coro) {
        SwitchToFiber(next as This fiber)
    }

    yield: final func {
        if(isMain) {
            raise("Scheduler error: yielded from main coro")
        }

        SwitchToFiber(parent)
    }

    setup: final func(coro: Coro, callback: Func) {
        if(fiber != null && !isMain) {
            DeleteFiber(fiber)
        }

        fiber = CreateFiber(DEFAULT_STACK_SIZE, callback as Closure thunk, callback as Closure context)

        if(!fiber) {
            raise("Could not create fiber")
        }

        parent = coro as This fiber
    }

    // Freeing a main fiber results in exiting the thread it was executed in
    free: final func {
        if(fiber) {
            DeleteFiber(fiber)
        }
    }
}

DeleteFiber: extern func(Pointer)
SwitchToFiber: extern func(Pointer)
CreateFiber: extern func(Int, Pointer, Pointer) -> Pointer
GetCurrentFiber: extern func -> Pointer
ConvertThreadToFiber: extern func(Pointer)

}

