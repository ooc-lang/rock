Iteratour: class <T> {}

main: func {

    iter := Iteratour<Int> new()
    printf("We've got a %s of %s\n", iter class name, iter T name)
    iter2 := Collection<Int> new() iterator()
    printf("We've got a %s of %s\n", iter2 class name, iter2 T name)
    
    coll := makeCollection(Int)
    printf("We've got a %s of %s\n", coll class name, coll T name)
    
}

Collection: class <T> {

    /*
    iterator: func -> Iteratour<T> {
        // ka-boom! T refers to "this T", in fact
        // but since it's parsed like a type, not a variable access,
        // it's written 'T' where it should be written 'this->T' in C.
        return Iteratour<T> new()
    }
    
    iterator2: func -> Iteratour<T> {
        localT := this T
        return Iteratour<localT> new()
    }
    */
    
    iterator: func -> Iteratour<T> {
        return Iteratour<T> new()
    }

}

makeCollection: func <T> (T: Class) -> Collection<T> {
    
    return Collection<T> new()
    
}
