
Dog : class {

    name: String
    age: Int
    
    // Wouhouu
    
    /* Comments! :D */
    
    shout: func {
        printf("Hey, world =D, my name is %s\n", name)
        return
    }

}

main: func -> Int {
    
    printf("Goodbye, cruel world\n")
    dog: Dog
    dog = gc_malloc(sizeof(Dog))
    dog class = Dog
    dog name = "Fido"
    dog shout()
    
    0
    
}
