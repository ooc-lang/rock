Test: class {
	init: func {}
}

operator + (first, second: Test) {
	"+ works" println()
}

main: func {
	one := Test new()
	one + one
}

