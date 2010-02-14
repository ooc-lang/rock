import structs/[List, ArrayList]

main: func {
	
	list := ArrayList<Int> new()
	
	"\nadding a few numbers.." println()
	for (i in 0..2) list add (i)
	for (i in 2..4) list += i
	
	"\ncreating another with 3, 4.." println()
	other := ArrayList<Int> new() .add(3) .add(4)
	
	testList(list as List<Int>, other as List<Int>)

}

testList: func(list, other: List<Int>) {
	
	"\nshowing content with get(i).." println()
	for (i in 0..list size()) printf("list get(%d) = %d\n", i, list get(i))

	"\nshowing content with [i].." println()
	for (i in 0..list size()) printf("list[%d] = %d\n", i, list[i])
	
	"\nshowing content with iterator" println()
	for (i: Int in list) printf("i = %d\n", i)
	
	"\nsetting fourth to 42.." println()
	list[3] = 42
	for (i in 0..list size()) printf("list[%d] = %d\n", i, list[i])
	
	"\nremoving an element.." println()
	list -= 0
	for (i in 0..list size()) printf("list[%d] = %d\n", i, list[i])
	
	"\nremoving another element.." println()
	list removeAt(2)
	for (i in 0..list size()) printf("list[%d] = %d\n", i, list[i])
	
	"\nshowing content of other list.." println()
	for (i in 0..other size()) printf("other[%d] = %d\n", i, other[i])
	
	"\nadding all to first list and showing!" println()
	list addAll(other as List<Int>)
	for (i in 0..list size()) printf("list[%d] = %d\n", i, list[i])
	
}
