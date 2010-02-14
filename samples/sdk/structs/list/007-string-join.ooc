import structs/ArrayList

main: func {
    list := ["Hello", "World!", "I", "am", "so", "excited."] as ArrayList<String>
    list join(" ... ") println()
}
