
Dog: class {
    
    name := static "Dilbert"

    // TODO: add a compile error at 'Dog print()' call if print is not declared static
    print: static func {
        printf("Hi, my name is %s\n", This name)
    }
    
}

main: func {
    Dog print()
}
