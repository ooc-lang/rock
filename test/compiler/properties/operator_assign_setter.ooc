foo: class{
    init: func(){}
    a: Int = 0
    b: Int{
        get { a }
        set(c){ a = c }
    }
}

bar := foo new()
bar b += 1
