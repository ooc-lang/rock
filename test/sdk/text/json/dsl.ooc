import text/json/DSL into dsl

dsl make(|make|
    make object(
        "key", "value",
        "yay", 3,
        "array", make array(
            "yesss maaaan",
            1327,
            false
        ),
        "another", make object(
            "fancy", "object",
            "VERY", 1337
        )
    )
) println()
