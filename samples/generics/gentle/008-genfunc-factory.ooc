Container: class <T> {
    
    printType: func {
        printf("Got a %s of type %s\n", This name, T name)  
    }
    
}

makeContainer: func (T: Class) -> Container<T> {
    return Container<T> new()
}

main: func {

    makeContainer(Int) printType()
    
}
