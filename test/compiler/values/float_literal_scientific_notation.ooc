check: func(a: Double, b: Double){
    if(a != b){
        "Fail! a: #{a toString()} not equals to b: #{b toString()}" println()
        exit(1)
    }
}

a: Double = 0.234e+3
b: Double = 234
c: Double = 0.45e-1
d: Double = 0.045

check(a,b)
check(c,d)
