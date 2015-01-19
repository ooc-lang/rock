IEquatable: interface <T> {
    equals: func(other: T) -> Bool
}

ValueEquatable: class <T> implements IEquatable<T> {
    value : Int = 0
    init: func(=value) {}
    equals: func(other: T) -> Bool {
        this value == other
    }
}

main: func -> Int{
    c := ValueEquatable <Int> new(1337)
    if(!c equals(1337) || (c equals(1338))){
        "class error" println()
        return 1
    }

    i := c as IEquatable<Int>
    if(!i equals(1337) || (i equals(1338))) {
        "interface error" println()
        return 1
    }

    0
}
