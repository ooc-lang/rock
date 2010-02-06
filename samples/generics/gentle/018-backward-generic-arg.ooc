num: func (arg: Double) {
	arg toString() println()
}

gen: func <T> (arg: T) {
	d = arg : Double
	num(d)
	
	d2 : Double
	d2 = arg
	num(d2)
	
	num(arg)
}

main: func {
	gen(3.14)
}
