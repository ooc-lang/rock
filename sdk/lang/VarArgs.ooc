
/*
 * Variable arguments are stored in there.
 *
 * This implementation is quite optimised.
 */

// that thunk is needed to correctly infer the 'T'. It shows at the
// same time the limitations of ooc generics and still how incredibly
// powerful they are.
__va_call: inline func <T> (f: Func <T> (T), T: Class, arg: T) {
    f(arg)
}

// we heard, more than once: don't use sizeof in ooc! why? because it'll
// actually be the size of the _class(), ie. the size of a pointer - which is
// what we want, so we're fine.
__sizeof: extern(sizeof) func (Class) -> SizeT

// used to align values on the pointer-size boundary, both for performance
// and to match the layout of structs
__pointer_align: inline func (s: SizeT) -> SizeT {
    // 'Pointer size' isn't a constant expression, but sizeof(Pointer) is.
    ps := static __sizeof(Pointer)
    diff := s % ps
    diff ? s + (ps - diff) : s
}

VarArgs: cover {

    args, argsPtr: UInt8* // because the size of stuff (T size) is expressed in bytes
    count: SSizeT // number of elements

    /*
     * Iterate through the arguments
     */
    each: func (f: Func <T> (T)) {
        countdown := count

        argsPtr := args
        while(countdown > 0) {
            // count down!
            countdown -= 1

            // retrieve the type
            type := (argsPtr as Class*)@ as Class

            version(!windows) {
                // advance of one class size
                argsPtr += Class size
            }
            version(windows) {
                if(type size < Class size) {
                    argsPtr += Class size
                } else {
                    argsPtr += type size
                }
            }

            // retrieve the arg and use it
            __va_call(f, type, argsPtr@)

            // skip the size of the argument - aligned on 8 bytes, that is.
            argsPtr += __pointer_align(type size)
        }
    }

    /*
     * private api used by C code
     */

    init: func@ (=count, bytes: SizeT) {
        args = gc_malloc(bytes + (count * Class size))
        argsPtr = args
    }

    /**
     * Internal testing method to add arguments
     */
    _addValue: func@ <T> (value: T) {
        // store the type
        (argsPtr as Class*)@ = T

        // advance of one class size
        argsPtr += Class size

        // store the arg
        (argsPtr as T*)@ = value

        // align on the pointer-size boundary
        argsPtr += __pointer_align(T size)
    }

    /**
     * @return an iterator that can be used to retrieve every argument
     */
    iterator: func -> VarArgsIterator {
        (args, count, true) as VarArgsIterator
    }

}

/**
 * Can be used to iterate over variable arguments - it has more overhead
 * than each() because it involves at least one memcpy, except in a future
 * where we take advantage of generic inlining.
 *
 * Apart from that, it's a regular iterator, except that next takes the
 * type that you want to retrieve.
 *
 * The only checking done is that the size of the type you're trying
 * to get and the size of the actual type must match. Otherwise, you're
 * free to mix and match up types as you wish - just be careful.
 */
VarArgsIterator: cover {
    argsPtr: UInt8*
    countdown: SSizeT
    first: Bool

    hasNext?: func -> Bool {
        countdown >= 0
    }

    // convention: argsPtr points to type of next element when called.
    next: func@ <T> (T: Class) -> T {
        if(countdown < 0) {
            Exception new(This, "Vararg underflow!") throw()
        }

        // count down!
        countdown -= 1

        nextType := (argsPtr as Class*)@ as Class
        result : T*
        version(!windows) {
            result = (argsPtr + Class size) as T*
            argsPtr += Class size + __pointer_align(nextType size)
        }
        version(windows) {
            if(nextType size > Class size) {
                result = (argsPtr + nextType size) as T*
                argsPtr += nextType size + __pointer_align(nextType size)
            } else {
                result = (argsPtr + Class size) as T*
                argsPtr += Class size + __pointer_align(nextType size)
            }
        }

        result@
    }

    getNextType: func@ -> Class {
        if (countdown < 0) Exception new(This, "Vararg underflow!") throw()
        (argsPtr as Class*)@ as Class
    }
}






