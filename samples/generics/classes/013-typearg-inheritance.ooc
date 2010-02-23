
AbstractContainer: class <T> {

    printType: func {
        printf("%s<%s>\n", This name, T name)
    }
    
}

Container: class <T> extends AbstractContainer<T> {
    
    printType: func {
        super()
        printf("%s<%s>\n", This name, T name)
    }
    
    removeAt: func (index: Int) -> T {
        printf("Removing %s #%d\n", T name, index); null
    }
    
    doThing: func {
        a := removeAt(42)
        printType()
    }
    
}

main: func {
    Container<Int> new() doThing()
}

