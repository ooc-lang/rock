import structs/[List, ArrayList]

duplicate: func (list: ArrayList<T>) -> ArrayList<T> {
    
    T := list T
    dupe := ArrayList<T> new()
    dupe addAll(list)
    return dupe
    
}

printType: func (object: Object) {
    
    T := object class
    printf("It's an %s", T name)
    if(T inheritsFrom(List)) {
        printf("<%s>", object as ArrayList<T> T name)
    }
    println()
    fflush(stdout)
    
}


main: func {

    chars := ArrayList<Char> new()
    chars add('a').add('b').add('c')
    printType(chars)
    chars2 := duplicate(chars)
    printType(chars2)
    
}
