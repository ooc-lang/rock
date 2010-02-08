
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
    print(Dog new())
    print(Cat new())
}

print: func (r: Representable) {
    r toString() println()
}
