import structs/ArrayList

main: func {
    
    list := ["John", "Doe"]
    firstname, lastname: String
    getNames(list, firstname&, lastname&)
    
    printf("My name is %s. %s %s.\n", lastname, firstname, lastname)
    
}

getNames: func <T> (list: ArrayList<T>, firstname, lastname: String*) {
    firstname@ = list[0]
    lastname@  = list[1]
}
