foo: class{
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
