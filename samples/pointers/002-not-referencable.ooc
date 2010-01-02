main: func {
    
    printReference(42&)
    
}

printReference: func (a: Int*) {
    
    printf("a = %d\n", a@)
    
}