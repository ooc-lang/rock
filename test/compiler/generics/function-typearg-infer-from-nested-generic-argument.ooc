
// regression test for https://github.com/nddrylliog/rock/issues/639
Bag: class <J, K, L> {
    j: J
    k: K
    l: L
    init: func (=j, =k, =l)
}

peekaboo: func <A, B, C, D, E, F> (arg: Bag<A, B, C>, arg2: Bag<D, E, F>) {
    "A = %s" printfln(A name)
    "B = %s" printfln(B name)
    "C = %s" printfln(C name)
    "D = %s" printfln(D name)
    "E = %s" printfln(E name)
    "F = %s" printfln(F name)
}

main: func {
    peekaboo(Bag new(3.14, 42, "Huhu"), Bag new(3.14, 42, "Huhu"))
}
