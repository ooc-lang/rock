
extend Int {
    plusFive ::= this + 5
}

extend String {
    hasWhitespace? ::= contains?(' ')
}

main: func {
    success? := true

    if(42 plusFive != 47 as Float) {
        success? = false
        "[FAIL] 42 plus five is 47, not %d" printfln(42 plusFive)
    }

    if("lolwut" hasWhitespace?) {
        success? = false
        "[FAIL] \"lolwut\" hasWhitespace? should be false, not true" println()
    }

    if (!success?) {
        "We've had errors" println()
        exit(1)
    }

    "Pass" println()
}
