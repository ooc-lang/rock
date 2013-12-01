Foo: class {
    init: func
    toString: func -> String { "Foo" }
}

Bar: class extends Foo {
    init: func
    toString: func -> String { "Bar" }
}

main: func -> Int {
    success := true

    "Testing custom toString" println()
    str := "#{Foo new()}#{Bar new()}"
    if(str != "FooBar") {
        "[FAIL] Final string should be FooBar, not %s" printfln(str)
        success = false
    } else {
        "[PASS]" println()
    }

    "Testing escape" println()
    str = "\#{foo}"
    if(str size != 6) {
        "[FAIL] Escaped string size should be 6, not %d" printfln(str size)
        success = false
    } else {
        "[PASS]" println()
    }

    success ? 0 : 1
}
