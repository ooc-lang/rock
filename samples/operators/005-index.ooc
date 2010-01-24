
Reverse: class {
    
    init: func {}
    
}

operator []  (r: Reverse, i: Int) -> Int    { -i }
operator []= (r: Reverse, i, v: Int) -> Int { printf("r[%d] = %d called!\n", i, v) }

main: func {
    
    r := Reverse new()
    printf("r[3] = %d\n", r[3])
    r[9] = 17
    
    return 0
    
}
