
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
    
    /*
    dog: Dog
    dog = gc_malloc(Dog instanceSize)
    dog class = Dog as Class
    */
    
    printf("Dog instanceSize = %d\n", Dog instanceSize)
    dog := (Dog alloc()) as Dog
    //dog : Dog
	
    dog name = "Fido"
    dog shout()
    
    0
    
}
