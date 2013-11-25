import text/json/DSL into dsl

main: func {
    result := dsl make(|make|
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
    )

    if (!result || result empty?()) {
        "Fail! result = %s" printfln(result)
        exit(1)
    }

    "Pass" println()
    exit(0)
}
