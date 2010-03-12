import structs/HashMap

main: func {
    map := HashMap<String, String> new()
    map["hello"] = "goodbye"
    map["yes"] = "no"
    map["hello"] println()
    map["yes"] println()
    map["always"] = "never"
    map["always"] println()
}
