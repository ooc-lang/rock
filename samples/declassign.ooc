include stdio

Int: cover from int
String: cover from char*

main: func -> Int {
    
    msg := "The answer is"
    answer = 42 : Int
    //x = 1, y = 2, z = 3 : Int
    printf("%s %d\n", msg, answer)
    
}

