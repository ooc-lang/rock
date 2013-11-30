import structs/[ArrayList, OrderedMultiMap]

main: func {
    stringString()

    "Pass" println()
}

stringString: func {
    keys := [
        "interpretation", "interpretations", "interpretative", "interpreted",
        "interpreting", "interpretive", "interprets", "misinterpret",
        "misinterpretation", "misinterpretations", "misinterpreted",
        "misinterpreting", "misinterprets", "reinterpret", "reinterpreted",
        "reinterprets", "reinterpreting", "reinterpretation",
        "reinterpretations", "deregulated", "deregulates", "deregulating",
        "deregulation", "regulated", "regulates", "regulating",
        "regulation","regulations", "regulator", "regulators", "regulatory",
        "unregulated", "revolutionary", "revolutionaries", "revolutionise",
        "revolutionised", "revolutionises", "revolutionising", "revolutionist",
        "revolutionists", "revolutions", "insignificant", "insignificantly",
        "significance", "significantly", "signified", "signifies", "signify",
        "signifying", "restructure", "restructured", "restructures",
        "restructuring", "structural", "structurally", "structured",
        "structures", "structuring", "unstructured", "invariable",
        "invariably", "variability", "variable", "variables", "variably",
        "variance", "variant", "variants", "variation", "variations", "varied",
        "varies", "varying", "violated", "violates", "violating", "violation",
        "violations", "Lorem", "ipsum", "dolor", "sit", "amet", "consectetur",
        "adipiscing", "elit", "Nam", "dolor", "ante", "tristique", "sed",
        "pulvinar", "nec", "auctor", "suscipit", "augue", "Suspendisse", "sit",
        "amet", "elit", "scelerisque", "iaculis", "lectus", "mattis",
        "lobortis", "justo", "Phasellus", "tincidunt", "consequat", "odio",
        "at", "aliquam", "erat", "porta", "id", "Sed", "et", "laoreet", "enim",
        "Fusce", "quis", "facilisis", "nisi", "Donec", "eu", "ipsum", "elit",
        "Donec", "rutrum", "tellus", "ac", "urna", "convallis", "ullamcorper",
        "Duis", "elementum", "arcu", "sagittis", "cursus", "sollicitudin",
        "augue", "augue", "suscipit", "libero", "eu", "ultricies", "arcu",
        "nisi", "et", "ante", "Fusce", "consectetur", "sagittis", "vulputate",
        "Fusce", "malesuada", "sapien", "lacus", "sit", "amet", "accumsan",
        "mauris", "aliquam", "ullamcorper", "Suspendisse", "neque", "massa",
        "convallis", "vel", "orci", "sit", "amet", "cursus", "mattis", "metus",
        "Cras", "sodales", "ligula", "imperdiet", "fermentum", "vestibulum",
        "Donec", "eu", "mauris", "a", "felis", "tincidunt", "aliquam", "Duis",
        "et", "mi", "metus", "Aenean", "aliquam", "ultrices", "tellus", "non",
        "pretium", "est", "fermentum", "venenatis", "Curabitur", "auctor",
        "enim", "risus", "ac", "commodo", "massa", "dictum", "in", "Praesent",
        "consequat", "est", "mattis", "sapien", "laoreet", "laoreet", "Nam",
        "et", "porttitor", "diam", "eget", "molestie", "turpis", "Vivamus",
        "iaculis", "venenatis", "suscipit", "Suspendisse", "faucibus", "eros",
        "quis", "odio", "vehicula", "eget", "consectetur", "turpis", "aliquam",
        "Nunc", "id", "justo", "est", "Nunc", "et", "tincidunt", "quam",
        "vitae", "euismod", "neque", "Donec", "non", "adipiscing", "nisl",
        "Pellentesque", "a", "mi", "a", "metus", "consequat", "vulputate",
        "Integer", "bibendum", "massa", "sit", "amet", "eros", "vestibulum",
        "vitae", "accumsan", "elit", "posuere", "Mauris", "tempus", "suscipit",
        "ante", "ac", "fermentum", "mi", "ornare", "a", "Pellentesque",
        "pellentesque", "libero", "ut", "ligula", "lobortis", "euismod",
        "Curabitur", "vitae", "ante", "et", "erat", "consequat", "blandit",
        "Vivamus", "tellus", "nunc", "volutpat", "eget", "molestie", "eu",
        "rutrum", "ut", "nunc", "Vivamus", "fringilla", "enim", "eget", "mi",
        "sodales", "tempor", "Aenean", "bibendum", "augue", "id", "dui",
        "scelerisque", "in", "mattis", "felis", "vestibulum", "Ut", "id",
        "vestibulum", "justo", "vitae", "pulvinar", "dui", "Aenean", "mattis",
        "risus", "leo", "Donec", "quis", "accumsan", "dui", "Ut", "porttitor",
        "lacus", "purus", "Maecenas", "sit", "amet", "magna", "sit", "amet",
        "ligula", "fermentum", "luctus", "Fusce", "ac", "ante", "eu", "est",
        "adipiscing", "pharetra", "ac", "non", "elit", "Vivamus", "sit",
        "amet", "fringilla", "lacus", "nec", "varius", "mauris", "Aenean",
        "sed", "elit", "nibh", "Phasellus", "aliquam", "nulla", "fermentum",
        "laoreet", "nulla", "ut", "pretium", "metus", "Cras", "metus",
        "sapien", "laoreet", "quis", "facilisis", "sed", "scelerisque", "eu",
        "quam", "Integer", "quis", "interdum", "libero", "In", "in", "justo",
        "sed", "nisi", "euismod", "ultrices", "a", "at", "arcu", "Phasellus",
        "ultrices", "bibendum", "consequat", "Nam", "ipsum", "diam",
        "tincidunt", "ut", "vulputate", "eu", "viverra", "nec", "turpis",
        "Nullam", "id", "elementum", "est", "Mauris", "at", "nunc",
        "facilisis", "vulputate", "justo", "eget", "adipiscing", "odio",
        "Donec", "luctus", "congue", "libero", "rhoncus", "dictum", "orci",
        "dignissim", "at", "Aenean", "nec", "dolor", "porttitor", "hendrerit",
        "neque", "in", "aliquam", "dui", "Cras", "auctor", "nibh", "nibh",
        "eget", "imperdiet", "arcu", "mollis", "in", "Donec", "aliquam",
        "laoreet", "ornare", "Proin", "in", "erat", "ornare", "sagittis",
        "erat", "et", "tempus", "sapien", "Nullam", "vel", "est", "non", "leo",
        "fringilla", "sagittis", "eu", "feugiat", "libero", "Proin", "porta",
        "vitae", "ligula", "eu", "scelerisque", "Curabitur", "dolor", "lacus",
        "scelerisque", "non", "congue", "at", "molestie", "ac", "lorem",
        "Integer", "rhoncus", "tellus", "vel", "ipsum", "consectetur",
        "feugiat", "Curabitur", "euismod", "porttitor", "magna", "vel",
        "tempor", "lacus", "varius", "non", "Curabitur", "ut", "massa", "sed",
        "nisi", "interdum", "euismod", "Vestibulum", "tincidunt", "elit",
        "non", "feugiat", "consectetur", "velit", "velit", "consequat", "erat",
        "id", "porttitor", "eros", "ligula", "vulputate", "urna", "Aliquam",
        "vitae", "neque", "quis", "enim", "rhoncus", "hendrerit", "ac",
        "adipiscing", "lacus", "Phasellus", "sed", "neque", "feugiat",
        "tempor", "est", "nec", "imperdiet", "purus", "Phasellus", "ut", "sem",
        "vitae", "mi", "adipiscing", "scelerisque", "Duis", "pulvinar",
        "purus", "eu", "tincidunt", "auctor", "mauris", "massa", "faucibus",
        "tortor", "id", "consectetur", "neque", "leo", "quis", "felis"
    ] as ArrayList<String>

    for (i in 0..keys size) {
        keys[i] = "#{keys[i]}-#{i}"
    }

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
        ensure(k, keys[i], "order key 1")
    }

    for ((i, v) in map) {
        ensure(v, keys[i], "order value 1")
    }

    {
        i := -1
        map each(|key, value|
            i += 1
            ensure(key, keys[i], "order key 2")
            ensure(value, keys[i], "order value 2")
        )
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
        exit(1)
    }
}

ensure: func ~bool (a, b: Bool, desc := "") {
    if (a != b) {
        "Fail! '#{a}' should equal '#{b}' (#{desc})" println()
        exit(1)
    }
}

ensure: func ~int (a, b: Int, desc := "") {
    if (a != b) {
        "Fail! '#{a}' should equal '#{b}' (#{desc})" println()
        exit(1)
    }
}


