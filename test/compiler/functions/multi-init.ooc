
intDone := false
strDone := false

describe("Should call right constructor based on suffix", ||
    Dog new(42)
    Dog new("43")

    expect(true, intDone)
    expect(true, strDone)
)

// support code

Dog: class {

    init: func ~int (a: Int) {
        intDone = true
    }
    
    init: func ~str (a: String) {
        strDone = true
    }

}

