
Pair: class template <T, V> {
    left: T
    right: V

    init: func (=left, =right)

    operator == (other: This<T, V>) -> Bool {
        left == other left && right == other right
    }
}


describe("class templates should work", ||
    pair1 := Pair<String, Int> new("hi", 0)
    pair2 := Pair<String, Int> new("world", 42)

    expect(false, pair1 == pair2)
)
