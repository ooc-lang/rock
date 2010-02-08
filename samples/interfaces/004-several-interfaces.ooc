
Representable: interface {
    toString: func -> String
}

Noisy: interface {
    makeNoise: func
}

Dog: class implements Representable, Noisy {
    growl: func { "Grrwoof woof!" println() }
    toString: func -> String { "Dog!" }
    run: func {}
    
    makeNoise: func { growl() }
}

Cat: class implements Representable, Noisy {
    meowl: func { "Meoowwwwww!" println() }
    beLazy: func {}
    toString: func -> String { "Cat!" }
    
    makeNoise: func { meowl() }
}

main: func {
    r := Dog new() as Representable
    print(r)
    print(Cat new())
    
    poke(Dog new())
    n := Cat new() as Noisy
    poke(n)
}

print: func (r: Representable) {
    r toString() println()
}

poke: func (n: Noisy) {
    n makeNoise()
}