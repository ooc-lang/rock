
/**
 * Portable ucontext-based coroutines implementation for cooperative multitasking.
 *
 * Largely based on Steve Dekorte's libcoroutine, see authors below.
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

    requestedStackSize: SizeT { get set }
    allocatedStackSize: SizeT
    stack: Pointer { get set }
    env: UContext
    isMain: Bool

    init: func {
        requestedStackSize = DEFAULT_STACK_SIZE
        allocatedStackSize = 0
    }

    allocStackIfNeeded: func {
        //"AllocStackIfNeeded of %p, alloc/req = %d/%d" format(this, allocatedStackSize, requestedStackSize) println()
        
        if (stack != null && allocatedStackSize > requestedStackSize) {
           gc_free(stack)
           stack = gc_malloc(requestedStackSize)
           allocatedStackSize = requestedStackSize
        }

        if (stack == null) {
            stack = gc_malloc(requestedStackSize)
            allocatedStackSize = requestedStackSize
        }
    }

    free: func {
        if(stack) {
            gc_free(stack)
        }
    }

    currentStackPointer: func -> UInt8* {
        a: UInt8
        b := a& // to avoid compiler warning about unused variables
        b
    }

    bytesLeftOnStack: func -> SSizeT {
        dummy: UChar
        p1: PtrDiff = dummy&
        p2: PtrDiff = currentStackPointer()

        start: PtrDiff = stack
        end: PtrDiff = stack + requestedStackSize

        stackMovesUp := (p2 > p1)
        if(stackMovesUp) { // like x86
            end - p1
        } else { // like OSX on PPC
            p1 - start
        }
    }

    stackSpaceAlmostGone: func -> Bool {
        bytesLeftOnStack() < MIN_STACK_SIZE
    }

    initializeMainCoro: func {
        isMain = true
    }

    startCoro: func (other: This, callback: Func) {
        other allocStackIfNeeded()
        other setup(||
            callback()
            "Scheduler error: returned from coro start function" println()
            exit(-1)
        )
        switchTo(other)
    }

    setup: func (callback: Func) {
        getcontext(env&)

        env stack stackPointer = stack
        env stack stackSize    = requestedStackSize
        env stack flags        = 0
        env link               = null

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
