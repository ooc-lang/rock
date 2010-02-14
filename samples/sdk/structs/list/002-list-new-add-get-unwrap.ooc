import structs/[List, ArrayList]

main: func {

	list := ArrayList<Int> new()
	list add(42)
	printf("Val is %d\n", list get(0))

}
