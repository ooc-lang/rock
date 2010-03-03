Container: class <T> {}

print: func <T> (t: Container<T>) {
	
	("T size == " + T size as Int + ", Pointer size == " + Pointer size as Int) println()
	
	match T {
		case Pointer => "Success!"
		case => "Fail :("
	} println()
	
}

Dog: class {
	
	age, length, weight: Int
	
}

main: func {
	
	print(Container<Dog> new())
	print(Container<Short*> new())
	
}
