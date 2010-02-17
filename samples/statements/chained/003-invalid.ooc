import structs/ArrayList

main: func {
    
    a := ArrayList<String> new()
    return a add("but"). add("does"). add("it"). add("work"). add("?")
    
    for(i in a) i println()
    
}