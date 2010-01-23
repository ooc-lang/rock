
Nut: class {
    
    cracker: Int
    
    init: func(cracker: Int) {
        this cracker = cracker
    }
    
}

operator <=> (n1, n2: Nut) -> Int { "<=> called!" println(); n1 cracker <=> n2 cracker }
operator <   (n1, n2: Nut) -> Int { "< called!" println();   n1 cracker <   n2 cracker }

main: func {
    
    n1 := Nut new(42)
    n2 := Nut new(217)
    
    printf("%3d <  %3d ? %d\n", n1 cracker, n2 cracker, n1 < n2)
    printf("%3d >  %3d ? %d\n", n1 cracker, n2 cracker, n1 > n2)
    
}
