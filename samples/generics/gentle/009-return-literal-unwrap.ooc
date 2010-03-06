Container: class <T> {
    get: func -> T {
        return 42
    }
}

makeContainer: func (V: Class) -> Container<V> {
    return Container<V> new()
}

main: func {
    //{
        cont := Container<Int> new()
        printf("Got a %s of %s\n", cont class name, cont T name);
        answer := cont get()
        printf("Type of answer is %s\n", answer class name)
        ("The answer is " + answer) println()
    //}
    
    //{
        //cont2 := makeContainer(Int) as Container<Int>
        //("The answer is still " + cont2 get()) println()
    //}
}
