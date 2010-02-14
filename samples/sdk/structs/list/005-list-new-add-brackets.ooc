import structs/[List, ArrayList]

main: func {

	list := ArrayList<Int> new()
	list add(42)
	val := list[0]
	("Val is " + val) println()

}
