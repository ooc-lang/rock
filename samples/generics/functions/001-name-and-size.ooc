
print: func <T> (value: T) {
    
    printf("Got a %s of size %zd\n", T name, T instanceSize)
    
    if(T == Int) {
        printf("Value = %d\n", value as Int)
    } else if(T == String) {
        printf("Value = %s\n", value as String)
    }
    
}

Dog: class {
    
}

main: func -> Int {
    
    print(42)
    print("Hogfather")
    //print(Dog new())
    
}
