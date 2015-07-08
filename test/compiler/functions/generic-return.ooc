
describe("should return proper type when explicitly specifying generic typeArg", ||
    v := blooey(Int)
    expect(42, v)
)

// support code

blooey: func <T> (T: Class) -> T {
    match T {
        case Int => 42
    }
}

