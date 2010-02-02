
Being: class {
    print: func {
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
        printf("Hi, I'm a Cat!\n")
    }
}

main: func {

    "\n==========\nCalling on Being" println()
    Being new() print()
    
    "\n==========\nCalling on Animal" println()
    Animal new() print()
    
    "\n==========\nCalling on Mammal" println()
    Mammal new() print()
    
    "\n==========\nCalling on Cat" println()
    Cat new() print()
    
}
