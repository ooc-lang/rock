Greeter: class {
    message: String

    init: func (=message) {
    }

    greet: unmangled(huhu) func {
        message println()
    }
}

huhu: extern func(Greeter)

main: func {
    g := Greeter new("Hello World!")
    g greet()
    huhu(g)
}
