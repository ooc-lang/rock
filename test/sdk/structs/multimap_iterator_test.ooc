
import structs/[HashMap, MultiMap]

main: func {
    testMap(MultiMap<String, String> new(), "123456")
    testMap(HashMap<String, String> new(), "246")

    "Pass" println()
}

testMap: func (map: HashMap<String, String>, control: String) {
    map put("a", "1")
    map put("a", "2")
    map put("b", "3")
    map put("b", "4")
    map put("c", "5")
    map put("c", "6")

    result := ""
    for (v in map) {
        result = result + v
    }

    if (result != control) {
        "Fail! for #{map class name} should be #{control}, is #{result}" println()
        exit(1)
    }
}

