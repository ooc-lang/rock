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

    startCoro: func(other: Coro, callback: Func) {
        other setup(this, ||
            callback()
            other switchTo(this)
        )
        switchTo(other)
    }

    switchTo: func(next: Coro) {
        SwitchToFiber(next as This fiber)
    }

    yield: func {
        if(isMain) {
            raise("Scheduler error: yielded from main coro")
        }

        SwitchToFiber(parent)
    }

    setup: func(coro: Coro, callback: Func) {
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
    free: func {
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

