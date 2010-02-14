import structs/[List, ArrayList]

main: func {

	list := ArrayList<Int> new()
	list add(1).add(1).add(2).add(3).add(5).add(8).add(13).add(21)
	
	for(i: Int in list) {
		printf("%d\n", i)
	}

}
