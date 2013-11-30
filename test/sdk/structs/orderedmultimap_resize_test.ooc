import structs/[ArrayList, OrderedMultiMap]

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
    keys := [
        "interpretation", "interpretations", "interpretative", "interpreted", "interpreting", "interpretive", "interprets", "misinterpret", "misinterpretation", "misinterpretations", "misinterpreted", "misinterpreting", "misinterprets", "reinterpret", "reinterpreted", "reinterprets", "reinterpreting", "reinterpretation", "reinterpretations", "deregulated", "deregulates", "deregulating", "deregulation", "regulated", "regulates", "regulating", "regulation","regulations", "regulator", "regulators", "regulatory", "unregulated", "revolutionary", "revolutionaries", "revolutionise", "revolutionised", "revolutionises", "revolutionising", "revolutionist", "revolutionists", "revolutions", "insignificant", "insignificantly", "significance", "significantly", "signified", "signifies", "signify", "signifying", "restructure", "restructured", "restructures", "restructuring", "structural", "structurally", "structured", "structures", "structuring", "unstructured", "invariable", "invariably", "variability", "variable", "variables", "variably", "variance", "variant", "variants", "variation", "variations", "varied", "varies", "varying", "violated", "violates", "violating", "violation", "violations"
    ] as ArrayList<String>
    map := OrderedMultiMap<String, String> new(1)

    for (k in keys) {
        map put(k, k)
    }

    ensure(map size, keys size, "map size")

    for (k in keys) {
        ensure(map contains?(k), true, "contains(#{k})")
        ensure(map get(k), k, "get(#{k})")
    }

    for ((i, k) in map getKeys()) {
        ensure(k, keys[i], "order")
    }

    map clear()

    for (k in keys) {
        ensure(map contains?(k), false)
    }

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


