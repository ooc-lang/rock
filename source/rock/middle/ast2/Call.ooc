
import Statement

Call: class extends Statement {

    name: String { get set }

    init: func (=name) {
        ("Got call to " + name) println()
    }

}
