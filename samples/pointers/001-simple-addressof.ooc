main: func {
    
    a := 42
    printReference(a&)
    
}

printReference: func (a: Int*) {
    
    printf("a = %d\n", a@)
    
}