Foo: interface {
    bar: func -> String
}

Bar: class implements Foo {
    x: String

    init: func(=x)

    bar: func -> String {
        x
    }
}

main: func {
    bar := Bar new("hi!")

    if(bar bar() != "hi!") {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
