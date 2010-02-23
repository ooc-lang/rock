
version(linux) {
    print: func {
        "Hello, Linux =)" println()
    }
}

version(apple) {
    print: func {
        "Hello, Mac =)" println()
    }
}

version(windows) {
    print: func {
        "Hello, Windows =)" println()
    }
}

version(!linux && !apple && !windows) {
    print: func {
        "Hi, stranger ;)" println()
    }
}

main: func {
    print()
}
