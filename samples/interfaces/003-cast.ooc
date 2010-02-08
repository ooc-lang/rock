
Representable: interface {
    toString: func -> String
}

Dog: class implements Representable {
    growl: func {}
    toString: func -> String { "Dog!" }
    run: func {}
}

Cat: class implements Representable {
    meowl: func {}
    beLazy: func {}
    toString: func -> String { "Cat!" }
}

main: func {
    r1 := Dog new() as Representable
    print(r1)
    r2 := Cat new() as Representable
    print(r2)
}

print: func (r: Representable) {
    r toString() println()
}
