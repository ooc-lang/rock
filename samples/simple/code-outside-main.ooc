
File: class {
    separator: String
    init: func(=separator) {}
}

file := File new("Bad")

// hehe, clever hack to get the version block to always be true
version(unix && !unix) {

    "Hi, world!" println()
    file separator = "Good"

    main: func {
        "It's all %s" format(file separator) println()
    }

}
