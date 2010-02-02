
Being: class {
    printf: func {
        printf("Hi, I'm a Being!\n")
    }
}

Animal: class extends Being {
    print: func {
        printf("Hi, I'm an Animal!\n")
    }
}

Mammal: class extends Animal {
    
}

Cat: class extends Mammal {
    print: func {
        super()
        printf("Hi, I'm a cat!\n")
    }
}

main: func {

    Being new() print()
    Animal new print()
    Mammal new() print()
    Cat new() print()
    
}
