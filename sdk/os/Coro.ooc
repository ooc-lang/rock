
/**
 * Portable ucontext-based coroutines implementation for cooperative multitasking.
 *
 * Originally based on Steve Dekorte's libcoroutine, see authors below.
 *
 * @author Steve Dekorte (libcoroutine - http://github.com/stevedekorte/coroutine)
 * @author Russ Cox (libcoroutine OSX10.6 fixes)
 * @author Edgar Toernig (Minimalistic cooperative multitasking - http://www.goron.de/~froese/)
 * @author Amos Wenger (nddrylliog)
 */
Coro: class {

    // this was originally commented '128k needed on PPC due to parser'
    // I have no idea what that means but 128k sounds reasonable.
    DEFAULT_STACK_SIZE := static 128 * 1_024
    MIN_STACK_SIZE := static 8_192

    stack: Pointer
    env: UContext
    isMain: Bool

    init: func {}

    initializeMainCoro: func {
        isMain = true
    }

    startCoro: func (other: This, callback: Func) {
        allocdStack: Char[DEFAULT_STACK_SIZE]
        other stack = allocdStack
        
        other setup(this, ||
            callback()
            "Scheduler error: returned from coro start function" println(stderr)
            exit(-1)
        )
        switchTo(other)
    }

    setup: func (coro: Coro, callback: Func) {
        getcontext(env&)

        env stack stackPointer = stack
        env stack stackSize    = DEFAULT_STACK_SIZE
        env stack flags        = 0
        env link               = coro env&

        makecontext(env&, callback as Closure thunk, 1, callback as Closure context)
    }

    switchTo: func (next: This) {
        swapcontext(env&, next env&)
    }

}

/* ------ C interfacing ------- */

include ucontext

StackT: cover from stack_t {
    stackPointer: extern(ss_sp) Pointer
    flags: extern(ss_flags) Int
    stackSize: extern(ss_size) SizeT
}

UContext: cover from ucontext_t {
    stack: extern(uc_stack) StackT
    link: extern(uc_link) Pointer
}

getcontext: extern func (ucp: UContext*) -> Int
setcontext: extern func (ucp: UContext*) -> Int
makecontext: extern func (ucp: UContext*, _func: Pointer, argc: Int, ...)
swapcontext: extern func (oucp: UContext*, ucp: UContext*) -> Int
