
Being: class {
    one := 1
}

Animal: class extends Being {
    two := 2    
}

Mammal: class extends Animal {
    three := 3
}

Cat: class extends Mammal {
    four := 4
    
    print: func {
        printf("1 = %d, 2 = %d, 3 = %d, 4 = %d", one, two, three, four)
    }
}

main: func {

    Cat new() print()
    
}
