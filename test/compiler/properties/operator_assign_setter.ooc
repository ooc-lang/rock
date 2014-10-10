foo: class{
    init: func(){}
    a: Int = 0
    b: Int{
        get { a }
        set(c){ a = c }
    }
}

foo2: cover{
    init: func(){}
    a: Int = 0
    b: Int{
        get { a }
        set(c){ a = c }
    }
}

bar := foo new()
bar b += bar b + 1
bar b += 1
bar b = bar b + 1

bar2 := foo2 new()
bar2 b += bar2 b + 1
bar2 b += 1
bar2 b = bar2 b + 1

bar b += bar2 b + bar b + 1

bar b += bar2 b
