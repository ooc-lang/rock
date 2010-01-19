include stdio

Natural: cover from int
Real: cover from float
Text: cover from char*

Dog: cover {
    name: String
}

main: func -> Int {
    
    d: Dog
    d name = "Fido"
    printf("The poor bastard's name is %s\n", d name)

    0
    
}

