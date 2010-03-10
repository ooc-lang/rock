import structs/ArrayList

main: func {
 
    print([1, 2, 3])
    print([4, 5, 6])
    
}

print: func (list: Int[]) {
    for(i in list) {
        i toString() println()
    }
}
