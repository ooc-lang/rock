
main: func {
    blah := DummyClass new()
	blah format("foobar %d", 10) println()
}

DummyClass: class {
    init: func() {}
    
    // This method will throw an error on the C side, as methods that deal with varargs have to be 'final'
    // This should probably throw an error on the rock side
    format: func(str: String, ...) -> String {
        list: VaList
        
        va_start(list, str)
        length := vsnprintf(null, 0, str, list) + 1
        output: String = gc_malloc(length)
        va_end(list)
        
        va_start(list, str)
        vsnprintf(output, length, str, list)
        va_end(list)
        return output
    }
}
