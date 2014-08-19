Readable: interface {
    read: func -> String
}

Writeable: interface {
    write: func(what: String)
}

Foo: class implements Readable, Writeable {
    _internal: String

    init: func

    read: func -> String { _internal }
    write: func(what: String) { _internal = what }
}

main: func {
    foo := Foo new()

    foo write("test")
    if(foo read() != "test") {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
