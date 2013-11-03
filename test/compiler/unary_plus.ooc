operator + (s: String) -> String { s }

main: func(argc: Int, argv: CString*) -> Int {
	success? := true

	"Tests for #484..." println()

	if(+42 == 42) {
		"[PASS]" println()
	} else {
		"[FAIL] +42 should be 42, not %d" printfln(+42)
		success? = false
	}

	if(+"foo" == "foo") {
		"[PASS]" println()
	} else {
		"[FAIL] +\"foo\" should be \"foo\" (because of overload), not %s" printfln(+"foo")
		success? = false
	}

	success? ? 0 : 1
}
