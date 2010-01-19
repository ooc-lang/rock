Foo: cover {
    //bar : static Int = 1
    bar: static Int
    
    baz: Float
}

main: func {
    
    Foo bar = 42
    printf("Foo bar = %d\n", Foo bar)
    
    foo : Foo
    foo baz = 3.14
    printf("foo baz = %.2f\n", foo baz)
    
}
