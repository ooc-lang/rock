Dog: class {

    name: String

    // overload the default constructor. No argument, no suffix.
    init: func {
        name = "Dogbert"
    }
    
    init: func ~withName (=name) {}
    
    sayHi: func { "Hi, I'm %s" format(name) println() }

}

PrettyDog: class extends Dog {
    
    // overload the default constructor. No argument, no suffix.
    init: func {
        name = "Pretty in pink"
    }
    
    init: func ~withName (.name) {
        this name = "Pretty " + name
    }
    
}

main: func {

    Dog new() sayHi()
    Dog new("Pintsize") sayHi()
    PrettyDog new() sayHi()
    PrettyDog new("Clango") sayHi()
    
}

