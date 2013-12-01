
Coyote: class {
    firstName := "Wile E."
    lastName := "Coyote"
    fullName ::= "#{firstName} #{lastName}"

    init: func
}

main: func {
    c := Coyote new()
    if (c fullName != "Wile E. Coyote") {
        "Fail! fullName = %s" printfln(c fullName)
        exit(1)
    }

    "Pass" println()
}
