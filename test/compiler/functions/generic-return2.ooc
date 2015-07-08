
describe("should be able to return Int value through two levels of generic functions", ||
    v := kablooey(Int)
    expect(42, v)
)

// support code

blooey: func <T> (T: Class) -> T {
    match T {
        case Int => 42
    }
}

kablooey: func <T> (T: Class) -> T {
    blooey(T)
}

