import structs/[List, ArrayList]

Cont: class {
	content := "Niark =D"
}

main: func {

	list := ArrayList<Int> new()
	list add(42)
	val := list get(0)
	("Val is " + val) println()
	
	list2 := ArrayList<String> new()
	list2 add("Ohoh.")
	val2 := list2 get(0)
	("Val2 is " + val2) println()
	
	list3 := ArrayList<Cont> new()
	list3 add(Cont new())
	val3 := list3 get(0) as Cont
	("Val3 is "+ val3 content) println()

}
