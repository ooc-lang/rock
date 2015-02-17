func1 := func {
    a := 1
    b := 2
    func2 := func { println((a + b) toString()) }
    func2()
}
func1()


func3 := func(f: Func(Int)){
    c := 1
    f(c)
}

func3(|x| 
    a := 2
    "%d %d" printfln(a, x)
)
