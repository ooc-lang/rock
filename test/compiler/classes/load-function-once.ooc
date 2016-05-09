
sideEffects: func -> Int {
    count := static 0
    count += 1
}

Base: class {
    count := static sideEffects()
}

Derived: class extends Base {}

describe("class load functions should only ever be evaluated once", ||
    expect(1, Base count)
)
