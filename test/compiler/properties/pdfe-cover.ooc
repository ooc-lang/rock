
import math

// Does not build
Point: cover {
    x, y: Float
    norm ::= (this x pow(2.0f) + this y pow(2.0f)) sqrt()
    normToo : Float { get { (this x pow(2.0f) + this y pow(2.0f)) sqrt() } }
}

main: func {
    p := (2, 2) as Point
    n1 := p norm
    n2 := p normToo
    if (n1 != n2) {
        "Fail: expected n1 == n2, but got %f != %f" printfln(n1, n2)
        exit(1)
    }
    
    "Pass" println()
}
