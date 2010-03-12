import structs/HashMap

printMap: func (map: HashMap<String, String>) {
    //for(key: String in map keys) {
    for(key: String in map getKeys()) {
        "%s: %s" format(key, map get(key)) println()
    }
}

main: func {
    map := HashMap<String, String> new()
    map put("db-libs", "DB libs!")
    map put("ui-libs", "UI libs!")
    map put("__result", "RESULT!")
    printMap(map)
    "---" println()
    map remove("__result")
    printMap(map)
}
