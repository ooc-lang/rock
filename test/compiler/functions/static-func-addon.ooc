Foo: class {
    x: Int

    init: func(=x)
}

extend Foo {
    bar: static func -> This {
        Foo new(42)
    }
}

main: func {
    bar := Foo bar()

    if(bar x != 42) {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
