import structs/ArrayList

Value: class <T> {

    val: T
    
    init: func(=val) {}

}

ValueList: class extends ArrayList<Value<String>> {}

test1: func <T> (ctx: Pointer, T:Class) -> T {
    /* works */
    ctx as ArrayList<Value<String>> get(0) as Value<String> val
}

test2: func <T> (ctx: Pointer, T:Class) -> T {
    /* works too! */
    ctx as ValueList get(0) as Value<String> val
}

main: func {
    vl := ArrayList<Value<String>> new()
    vl add(Value<String> new("Yay!"))
    test1(vl, String) println()
    test2(vl, String) println()
}
