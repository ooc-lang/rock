
/**
 * exceptions
 */
Exception: class {

    origin: Class
    msg : String

    init: func ~originMsg (=origin, =msg) {}
    init: func ~noOrigin (=msg) {}

    crash: func {
        fflush(stdout)
        x := 0
        x = 1 / x
        printf("%d", x)
    }

    getMessage: func -> String {
        //max := const 1024
        max : const Int = 1024
        buffer := gc_malloc(max) as String
        if(origin) snprintf(buffer, max, "[%s in %s]: %s\n", this as Object class name, origin name, msg)
        else snprintf(buffer, max, "[%s]: %s\n", this as Object class name, msg)
        return buffer
    }

    print: func {
        fprintf(stderr, "%s", getMessage())
    }

    throw: func {
        print()
        crash()
    }

}
