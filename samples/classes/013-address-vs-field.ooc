
Array: class {
    
    kalamazoo := 42
    kalamazoo: func -> Int { kalamazoo }
    
}

main: func {
    array := Array new()
    printf("Array kalamazoo   = %d\n", Array kalamazoo)
    printf("array kalamazoo() = %d\n", array kalamazoo())
    printf("array kalamazoo   = %d\n", array kalamazoo)
}
