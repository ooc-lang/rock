
Animal: class {
    
    //type := static "Animal"
    type : static String = "Animal"
    
}

Dog: class extends Animal {
    
    //name := static "Dilbert"
    name : static String = "Dilbert"

    // TODO: add a compile error at 'Dog print()' call if print is not declared static
    print: static func {
        printf("Hi, I'm a %s my name is %s\n", This type, This name)
    }
    
}

main: func {
    Dog print()
}
