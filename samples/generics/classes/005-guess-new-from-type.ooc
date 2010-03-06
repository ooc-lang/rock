Container: class <T> {
    
    init: func {
        printf("init: Got T = %p\n", T)
    }
    
    /*
     * The above declaration of init is effectively equivalent to the following code:
    
    init: func (=T) {
        printf("init: Got T = %p\n", T)
    }
    new: static func <T> -> This {
        printf("new:  Got T = %p\n", T)
        this := This class alloc() as This
        init(T)
        return this
    }

    * 
    */

    printy: func {
        printf("printy: got T = %p\n", T)
        ("Container of type [" + T name + "]") println()
    }
    
    printyToo: static func <T> {
        ("printyToo got type [" + T name + "]") println()
    }

}

main: func {

    cont := Container<Int> new()
    cont printy()
    Container<Int> printyToo()

}
