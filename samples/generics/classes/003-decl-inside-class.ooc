Provider: class <TOOPAK> {

    provide: func -> TOOPAK {
        a := 42
        return a
    }
    
}

Getter: class <T> {

    field : T
    data : T*
    
    init: func {
        data = gc_malloc(T size)
    }
    
    get: func(prov: Provider<T>) -> T {
        printf("Got T = %s, T size = %d\n", T name, T size)

        // this should work:
        //element: T = gc_malloc(T size)

        // and this :
        //element: T
        //element = prov provide()

        // and this :
        element := prov provide()
        
        printf("Got element as Int = %d\n", element as Int)
        return element
    }

    /*
    get2: func(prov: Provider<T>) -> T {
        field = prov provide()
        return field
    }
    
    get3: func(prov: Provider<T>) -> T {
        //data@ = prov provide()
        //return data@
    }
    */
    
}

main: func {

    prov := Provider<Int> new()
    printf("The answer is %d\n", prov provide())
    
    gett := Getter<Int> new()
    
    printf("The answer is also %d\n", gett get(prov))
    //printf("The answer is %d, too.\n", gett get2(prov))
    //printf("The answer is still %d\n", gett get3(prov))

}
