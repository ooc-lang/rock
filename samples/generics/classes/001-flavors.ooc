id: func <T> (t: T) -> T { t }

My: class {

    id: static func <T> (t: T) -> T { t }

}

My2: class {

    init: func {}

    id: func <T> (t: T) -> T { t }

}

main: func {

    printf("regular  %d == %d\n", 42, id(42))
    printf("static   %d == %d\n", 42, My id(42))
    my2 := My2 new()
    printf("instance %d == %d\n", 42, my2 id(42))

}
