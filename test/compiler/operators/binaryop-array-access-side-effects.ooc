SimpleStack: class <T> {
    _data: T*
    _count: SizeT = 0
    _capacity: SizeT = 8
    init: func { this _data = gc_malloc(this _capacity * T size) }
    push: func (element: T) {
        this _data[this _count] = element
        this _count += 1
    }

    pop: func -> T {
        this _data[this _count -= 1]
    }
}

describe("binary operator and array access existance of side effects should be correctly detected", ||
    stack := SimpleStack<Int> new()
    stack push(1) . push(2) . push(3)

    a := stack pop()
    stack pop()
    b := stack pop()

    expect(3, a)
    expect(1, b)
)
