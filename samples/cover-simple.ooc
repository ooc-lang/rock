include stdio

Int: cover from int
Float: cover from float
String: cover from char*

Dog: cover {
    name: String
}

main: func -> Int {
    
    d: Dog
    d name = "Fido"
    
}

