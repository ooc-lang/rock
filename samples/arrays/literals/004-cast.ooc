import structs/ArrayList

main: func {
 
    print([1, 2, 3] as ArrayList<Int>)
    print([4, 5, 6] as ArrayList<Int>)
    
}

print: func (list: Int[]) {
    for(i in list) {
        i toString() println()
    }
}
