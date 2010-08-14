
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
        if (stack != null && allocatedStackSize > requestedStackSize) {
           gc_free(stack)
           stack = gc_malloc(requestedStackSize)
           "Coro_%p re-allocating stack size %i" printfln(this, requestedStackSize)
        }

        if (stack == null) {
            stack = gc_malloc(requestedStackSize)
           "Coro_%p allocating stack size %i" printfln(this, requestedStackSize)
        }
    }

    free: func {
        if(stack) {
            gc_free(stack)
        }
        "Coro_%p free" printfln(this)
    }

    currentStackPointer: func -> UInt8* {
        a: UInt8
        b := a& // to avoid compiler warning about unused variables
        b
    }

    bytesLeftOnStack: func -> SizeT {
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
        other setup(callback)
        switchTo(other)
    }

    setup: func (callback: Func) {
        getcontext(env&)

        env stack stackPointer = stack + requestedStackSize - 8
        env stack stackSize    = requestedStackSize
        env stack flags        = 0
        env link               = null

        "Setting up Closure %p, callback thunk/context = %p/%p, env& = %p" printfln(this, callback as Closure thunk, callback as Closure context, env&)
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














