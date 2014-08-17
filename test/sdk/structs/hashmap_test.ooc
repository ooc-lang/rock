import structs/HashMap

fails := false

main: func {
    stringString()

    if (fails) {
        "We've had failures" println()
        exit(1)
    }

    "Pass" println()
}

stringString: func {
    map := HashMap<String, String> new()
    map put("a", "abaka")
    map put("b", "batavia")
    map put("c", "catwalk")

    ensure(map size, 3, "map size")
    ensure(map getKeys() size, 3, "map keys size")
    ensure(map get("a"), "abaka")
    ensure(map get("b"), "batavia")
    ensure(map get("c"), "catwalk")
    ensure(map contains?("a"), true)
    ensure(map contains?("b"), true)
    ensure(map contains?("c"), true)

    map remove("a")
    ensure(map contains?("a"), false)
    ensure(map size, 2, "map size")
    ensure(map getKeys() size, 2, "map keys size")

    map remove("b")
    ensure(map contains?("b"), false)
    ensure(map size, 1, "map size")
    ensure(map getKeys() size, 1, "map keys size")

    map clear()
    ensure(map contains?("c"), false)
    ensure(map size, 0, "map size")
    ensure(map getKeys() size, 0, "map keys size")
}

ensure: func ~str (a, b: String, desc := "") {
    if (a != b) {
        "Fail! '#{a}' should equal '#{b}' (#{desc})" println()
        fails = true
    }
}

ensure: func ~bool (a, b: Bool, desc := "") {
    if (a != b) {
        "Fail! '#{a}' should equal '#{b}' (#{desc})" println()
        fails = true
    }
}

ensure: func ~int (a, b: Int, desc := "") {
    if (a != b) {
        "Fail! '#{a}' should equal '#{b}' (#{desc})" println()
        fails = true
    }
}

