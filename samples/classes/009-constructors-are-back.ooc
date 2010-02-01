Dog: class {

    name: String

    // overload the default constructor. No argument, no suffix.
    init: func {
        name = "Dogbert"
    }
    
    init: func ~withName (=name) {}
    
    sayHi: func -> { "Hi, I'm %s\n" format(name) println() }

}

PrettyDog: class {
    
    name: String
    
    // overload the default constructor. No argument, no suffix.
    init: func {
        name = "Pretty in pink"
    }
    
    init: func ~withName (.name) {
        this name = "Pretty " + name
    }
    
}

main: func {

    d1 := Dog new()
    d2 := Dog new("Pintsize")
    d3 := PrettyDog new()
    d4 := PrettyDog new("Clango")
    
}

