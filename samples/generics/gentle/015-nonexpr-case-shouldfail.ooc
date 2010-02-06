myFunc: func <T> (blub: T) -> T {
	value : T = match {
		case false => if(true) {}
		case true => "hohoho, it should fail"
	}
	return value
}

main: func {
	myFunc(42) as String println()
}
