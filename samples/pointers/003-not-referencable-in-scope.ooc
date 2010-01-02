main: func {
 
    // it should create the temp variable in the if, not outside
    if(true) {
        printReference(42&)
    }
    
}

printReference: func (a: Int*) {
    
    printf("a = %d\n", a@)
    
}