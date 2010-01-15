Dog: cover {
    
    name: String
    
    println: func {
        //printf("Hi, my name is %s\n", this name)
        printf("Hi, my name is %s\n", name)
    }
    
}

printf: extern func {}

main: func -> Int {
    
    msg := "The answer is"
    answer = 42 : Int
    printf("%s %d\n", msg, answer)
    
    x = 1, y = 2, z = 3 : Int
    
    f := x as Float
    f = 314
    
    d: Dog
    d name = "Fido"
    printf("The name of my dog is %s\n", d name)
    d println()
    
}

