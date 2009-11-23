include stdio

Int: cover from int
Float: cover from float
String: cover from char*

Dog: cover {
    name: String
}

main: func -> Int {
    
    /*
    msg := "The answer is"
    answer = 42 : Int
    printf("%s %d\n", msg, answer)
    
    x = 1, y = 2, z = 3 : Int
    
    f := x as Float
    f = 314
    */
    
    d: Dog
    d name = "Fido"
    printf("The name of my dog is %s\n", d name)
    
}

