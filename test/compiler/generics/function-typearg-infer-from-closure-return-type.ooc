Foo: class <T, K, V, Z> { init: func }

f: func <Oh, My, God> (foo: Func -> Foo<Oh, Int, My, God>) {
    Oh name println()
    My name println()
    God name println()
}

describe("Typeargs should be inferred from closure argument return type", ||
    f(|| Foo<String, Int, Char, String> new())
)
