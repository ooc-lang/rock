import ../Coro

version(unix || apple) {

CoroUnix: class extends Coro {

    stack: UInt8*
    env: UContext

    init: func

    startCoro: func (other: Coro, callback: Func) {
        other as This allocStackIfNeeded()
        other as This setup(this, ||
            callback()
        )
        switchTo(other)
    }

    setup: func (coro: Coro, callback: Func) {
        getcontext(env&)

        env stack address = stack
        env stack size    = DEFAULT_STACK_SIZE
        env stack flags   = 0
        env link          = coro as This env&

        GC_add_roots(
            stack,
            stack + DEFAULT_STACK_SIZE
        )

        makecontext(env&, callback as Closure thunk, 1, callback as Closure context)
    }

    switchTo: func (next: Coro) {
        GC_stackbottom = next as This env stack address
        swapcontext(env&, next as This env&)
    }

    yield: func {
        // A main coro cannot yield
        if(isMain) {
            raise("Scheduler error: yielded from main coro")
        }

        previousCtx := (env link as UContext*)@
        GC_stackbottom = previousCtx stack address
        swapcontext(env&, previousCtx&)
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

}

