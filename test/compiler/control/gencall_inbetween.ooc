
main: func {

    cell := Cell new("pass")

    if (false) {
        // Muffin
    } else {
        (_, _) := Duplicator dup(cell get())
    }

}

Duplicator: class {
    dup: static func (a: String) -> (String, String) {
        a println()
        (a, a)
    }
}

