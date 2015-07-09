include ./constnum

SIG1: extern const Int

foo: func<T>(a: T){
    match(a){
        case b: Int => "matched!" 
        case => Exception new("error") throw()
    }
}

main: func{ foo(SIG1) }
