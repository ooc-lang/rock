Person: class {
    name: String
    
    init: func (=name) {}

    sayHello: func {
        "Hello, I am %s" format(name) println()
    }
}

globalPerson := Person new("Huhu")

someFunction: func -> Person {
    Person new("Blah")
}

main: func {
    globalPerson sayHello()
    someFunction() sayHello()
    a := globalPerson as Pointer
    a as Person sayHello()
}
