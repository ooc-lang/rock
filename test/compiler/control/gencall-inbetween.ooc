
describe("generic call should not happen between if and else", ||
    cell := Cell new("pass")

    if (false) {
        // Muffin
    } else {
        (a, b) := Duplicator dup(cell get())
        expect("pass", a)
        expect(a, b)
    }
)

// support code

Duplicator: class {
    dup: static func (a: String) -> (String, String) {
        (a, a)
    }
}

