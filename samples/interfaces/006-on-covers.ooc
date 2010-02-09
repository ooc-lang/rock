
Representable: interface {
    toString: func -> String
}

Score: cover from Int implements Representable {
    toString: func -> String {
        this as Int toString()
    }
}

main: func {
    
    s := 123456 as Score
    print(s)
    
}

print: func (r: Representable) {
    r toString() println()
}