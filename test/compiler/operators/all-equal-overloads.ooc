
Foo: class {
    value: Int
    init: func(=value)
}

output := ""

operator + (left, right: Foo) -> Foo {
    output += "+ "
    Foo new(left value + right value)
}
operator - (left, right: Foo) -> Foo {
    output += "- "
    Foo new(left value + right value)
}
operator * (left, right: Foo) -> Foo {
    output += "* "
    Foo new(left value + right value)
}
operator ** (left, right: Foo) -> Foo {
    output += "** "
    Foo new(left value + right value)
}
operator / (left, right: Foo) -> Foo {
    output += "/ "
    Foo new(left value + right value)
}
operator % (left, right: Foo) -> Foo {
    output += "% "
    Foo new(left value + right value)
}
operator >> (left, right: Foo) -> Foo {
    output += ">> "
    Foo new(left value + right value)
}
operator << (left, right: Foo) -> Foo {
    output += "<< "
    Foo new(left value + right value)
}
operator | (left, right: Foo) -> Foo {
    output += "| "
    Foo new(left value + right value)
}
operator ^ (left, right: Foo) -> Foo {
    output += "^ "
    Foo new(left value + right value)
}
operator & (left, right: Foo) -> Foo {
    output += "& "
    Foo new(left value + right value)
}

describe("All operators should be overloadable", ||
    foo := Foo new(1)

    foo = foo + Foo new(2) // +
    foo += Foo new(3) // +

    foo = foo - Foo new(2) // -
    foo -= Foo new(3) // -

    foo = foo * Foo new(2) // *
    foo *= Foo new(3) // *

    foo = foo ** Foo new(2) // **
    foo **= Foo new(3) // **

    foo = foo / Foo new(2) // /
    foo /= Foo new(3) // /

    foo = foo % Foo new(2) // %
    foo %= Foo new(3)

    foo = foo >> Foo new(2) // >>
    foo >>= Foo new(3)

    foo = foo << Foo new(2) // <<
    foo <<= Foo new(3) 

    foo = foo | Foo new(2) // |
    foo |= Foo new(3)

    foo = foo ^ Foo new(2) // ^
    foo ^= Foo new(3)

    foo = foo & Foo new(2) // & 
    foo &= Foo new(3)

    expect("+ + - - * * ** ** / / % % >> >> << << | | ^ ^ & & ", output)
)


