main: func -> Int{
    a := 10
    b := 5
    (a, b) = (b, a+b)
    if(a != 5 || b != 15) exit(1)

    (a, b) = (b+a, a+b)
    if(a != 20 || b != 20) exit(1)

    (a, b) = (b+a, a)
    if(a != 40 || b != 20) exit(1)

    (a, b) = (b+a, b)
    if(a != 60 || b != 20) exit(1)

    (a, b) = (b, foo(a,b))
    if(a != 20 || b != 80) exit(1)

    0
}

foo: func(a,b: Int) -> Int{
    a+b
}
