tfoo: class<T>{
    init: func(){}
    a: T
    b: T{
        get { a }
        set(c){ a = c }
    }
}

main: func -> Int{
    tbar := tfoo<Int> new()
    tbar a = 1
    if(tbar a as Int != 1){
        "error get_a" println()
        return 1
    }
    if(tbar b != 1){
        "error get_b" println()
        return 1
    }
    tbar b = 2
    if(tbar a as Int != 2){
        "error set_b, a %s" printfln()
        return 1
    }
    if(tbar b != 2){
        "error set_get_b" println()
        return 1
    }
    0
}
