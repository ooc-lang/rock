Container: class <T> {
	
	init: func {
		printf("Just created a Container<%s>\n", T name)
	}
	
}

Dog: class {
	
	age, length, weight: Int
	
}

main: func {
	
	cont := Container<Dog> new()
	("cont T size == " + cont T size as Int + ", Pointer size == " + Pointer size as Int) println()
	
	match cont T {
		case Pointer => "Success!"
		case => "Fail :("
	} println()
	
	cont = Container<Short*> new()
	("cont T size == " + cont T size as Int + ", Pointer size == " + Pointer size as Int) println()
	
	match cont T {
		case Pointer => "Success!"
		case => "Fail :("
	} println()
	
}
