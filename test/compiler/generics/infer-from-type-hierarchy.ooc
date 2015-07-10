
import structs/Stack

done := false

Node: class {
    init: func
    doStuff: func {
        done = true
    }
}

Trail: class extends Stack<Node> {
    init: func {
        super()
        push(Node new())
    }
}

getType: func <T> (t: T) -> String {
    T name
}

describe("wtf", ||
    t := Trail new()

    for (tuvalu in t backward()) {
        tuvalu doStuff()
    }

    expect(true, done)
)

