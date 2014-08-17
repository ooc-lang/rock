import structs/[MultiMap, List]

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
    map := MultiMap<String, String> new()

    map put("a", "one")
    ensure(map size, 1, "map size")
    ensure(map getKeys() size, 1, "map keys size")
    ensure(map get("a"), "one")

    map put("a", "two")
    ensure(map size, 1, "map size")
    ensure(map getKeys() size, 1, "map keys size")
    ensure(map get("a"), "two")

    res := map getAll("a")
    match res {
        case list: List<String> =>
            ensure(list size, 2, "list size")
            ensure(list[0], "one", "list[0]")
            ensure(list[1], "two", "list[1]")
        case =>
            "Fail: res is supposed to be a list!" println()
            fails = true
    }

    map remove("a")
    ensure(map size, 1, "map size")
    ensure(map getKeys() size, 1, "map keys size")
    ensure(map get("a"), "one")

    map clear()
    ensure(map contains?("a"), false)
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

