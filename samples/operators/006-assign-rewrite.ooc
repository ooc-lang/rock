
Nut: class {
    
    cracker: Int
    
    init: func (cracker: Int) {
        this cracker = cracker
    }
    
}

operator + (n1, n2: Nut) -> Nut { Nut new(n1 cracker + n2 cracker) }
operator - (n1, n2: Nut) -> Nut { Nut new(n1 cracker - n2 cracker) }
operator / (n1, n2: Nut) -> Nut { Nut new(n1 cracker / n2 cracker) }

main: func {
    
    n1 := Nut new(7)
    n2 := Nut new(1990)
    
    printf("%d + %d = ", n1 cracker, n2 cracker)
    n1 += n2
    printf("%d\n", n1 cracker)
    
    printf("%d - %d = ", n1 cracker, n2 cracker)
    n1 -= n2
    printf("%d\n", n1 cracker)
    
    printf("%d / %d = ", n2 cracker, n1 cracker)
    n2 /= n1
    printf("%d\n", n2 cracker)
    
}
