
/*
 * Variable arguments are stored in there.
 *
 * This implementation is quite optimised.
 */

// that's one *sexy* hack.
__va_call: func <T> (f: Func <T> (T), T: Class, arg: T) {
    f(arg)
}

/*  */
VarArgs: class {

    args, argsPtr: UInt8* // because the size of stuff (T size) is expressed in bytes
    count: SSizeT // number of elements
    
	/*
     * public api for retrieving varargs
     */

    /*
     * Iterate through the arguments
     */
    each: func (f: Func <T> (T)) {
        countdown := count

        argsPtr := args
        while(countdown > 0) {
            // retrieve the type
            type := (argsPtr as Class*)@ as Class
            "argsPtr = Got type %p" format(type) println()
            "Got type %s, of type size %zd" format(type name ? type name toCString() : "nil" toCString(), type size)
            argsPtr += Class size

            // retrieve the arg and use it
            "Now argsPtr = %p, value is %d" format(argsPtr, (argsPtr as Int*)@) println()
            __va_call(f, type, argsPtr@)
            
            argsPtr += type size

            countdown -= 1 // count down!
        }
    }

	/*
     * private api used by C code
     */
    
	init: func (=count, bytes: SizeT) {
        args = gc_malloc(bytes + (count * Class size))
        argsPtr = args
    }
    
	_addValue: func <T> (value: T) {
        "Adding value %d of type (%p) %s, of type size %zd" format(value as Int, T, T name ? T name toCString() : "(nil)" toCString(), T size) println()

        // store the type
        (argsPtr as Class*)@ = T
        argsPtr += Class size

        // store the arg
        memcpy(argsPtr, value&, T size)
        argsPtr += T size
    }
    
}
/* */
