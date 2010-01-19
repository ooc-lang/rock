
id: func <T> (t: T) -> T { t }

main: func -> Int {

    printf("%s %d, not %.2f\n", id("The answer is"), id(42), id(3.14))
    return 0
    
}
