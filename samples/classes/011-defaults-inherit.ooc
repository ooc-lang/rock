
Being: class {
    one := 1
}

Animal: class extends Being {
    two := 2    
}

Mammal: class extends Animal {
    
}

Cat: class extends Mammal {
    three := 3
    
    print: func {
        printf("1 = %d\n2 = %d\n3 = %d\n", one, two, three)
    }
}

main: func {

    Cat new() print()
    
}
