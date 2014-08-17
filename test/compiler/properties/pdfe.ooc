
Coyote: class {
    firstName := "Wile E."
    lastName := "Coyote"
    fullName ::= "#{firstName} #{lastName}"

    init: func
}

main: func {
    c := Coyote new()
    fullName := c fullName
    if (fullName != "Wile E. Coyote") {
        "Fail! fullName = %s" printfln(fullName)
        exit(1)
    }

    "Pass" println()
}
