extend Int {
    plusFive: Int {
        get {
            this + 5
        }
    }
}

extend String {
    hasWhitespace?: Bool { get { this contains?(' ') } }
}

main: func(argc: Int, argv: CString*) -> Int {
    success? := true

    "Tests for #711..." println()

    if(42 plusFive == 47 as Float) {
        "[PASS]" println()
    } else {
        success? = false
        "[FAIL] 42 plus five is 47, not %d" printfln(42 plusFive)
    }


    if(!"lolwut" hasWhitespace?) {
        "[PASS]" println()
    } else {
        success? = false
        "[FAIL] \"lolwuht\" hasWhitespace? should be false, not true" println()
    }

    success? ? 0 : 1
}
