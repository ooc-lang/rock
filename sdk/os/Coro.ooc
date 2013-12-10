
/**
 * Portable ucontext-based coroutines implementation for cooperative multitasking.
 *
 * Based on the work of:
 *  - Steve Dekorte (libcoroutine - http://github.com/stevedekorte/coroutine)
 *  - Russ Cox (libcoroutine OSX10.6 fixes)
 *  - Edgar Toernig (Minimalistic cooperative multitasking - http://www.goron.de/~froese/)
 */
Coro: class {

    // 128k stack = room for quite a few function calls
    DEFAULT_STACK_SIZE := static 128 * 1_024

    stack: UInt8*
    env: UContext
    isMain: Bool

    init: func

    initializeMainCoro: func {
        isMain = true
    }

    startCoro: func (other: This, callback: Func) {
        other allocStackIfNeeded()
        other setup(this, ||
            callback()
            raise("Scheduler error: returned from coro start function")
            exit(-1)
        )
        switchTo(other)
        other free()
    }

    setup: func (coro: Coro, callback: Func) {
        getcontext(env&)

        env stack address = stack
        env stack size    = DEFAULT_STACK_SIZE
        env stack flags   = 0
        env link          = coro env&

        GC_add_roots(
            stack,
            stack + DEFAULT_STACK_SIZE
        )

        makecontext(env&, callback as Closure thunk, 1, callback as Closure context)
    }

    switchTo: func (next: This) {
        GC_stackbottom = next env stack address
        swapcontext(env&, next env&)
    }

    allocStackIfNeeded: func {
        if (!stack) {
            stack = coro_malloc(DEFAULT_STACK_SIZE)
        }
    }

    free: func {
        GC_remove_roots(
            stack,
            stack + DEFAULT_STACK_SIZE
        )

        if (stack) {
            coro_free(stack)
            stack = null
        }
    }

}

/* ------ C interfacing ------- */

coro_malloc: extern(malloc) func (s: SizeT) -> Pointer
coro_free: extern(free) func (p: Pointer)

include ucontext | (_XOPEN_SOURCE=600)

StackT: cover from stack_t {
    address: extern(ss_sp) Pointer
    flags: extern(ss_flags) Int
    size: extern(ss_size) SizeT
}

UContext: cover from ucontext_t {
    stack: extern(uc_stack) StackT
    link: extern(uc_link) Pointer
}

getcontext: extern func (ucp: UContext*) -> Int
setcontext: extern func (ucp: UContext*) -> Int
makecontext: extern func (ucp: UContext*, _func: Pointer, argc: Int, ...)
swapcontext: extern func (oucp: UContext*, ucp: UContext*) -> Int

GC_add_roots: extern func (Pointer, Pointer)
GC_remove_roots: extern func (Pointer, Pointer)
GC_stackbottom: extern UInt8*

