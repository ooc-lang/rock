
/**
 * exceptions
 */
Exception: class {

    origin: Class
    msg : String

    init: func ~originMsg (=origin, =msg) {}
    init: func ~noOrigin (=msg) {}
    init: func ~charNoOrigin(aMsg: Char*) { msg = String new(aMsg) }


    crash: func {
        fflush(stdout)
        x := 0
        x = 1 / x
        printf("%d", x)
    }

    getMessage: func -> String {
        //max := const 1024
        max : const Int = 1024
        buffer := String new (max)
        if(origin) snprintf(buffer data, max, "[%s in %s]: %s\n", this as Object class name data, origin name data, msg data)
        else snprintf(buffer data, max, "[%s]: %s\n", this as Object class name data, msg data)
        return buffer
    }

    print: func {
        fprintf(stderr, "%s", getMessage() )
    }

    throw: func {
        print()
        crash()
    }

}
