import structs/[Array, ArrayList]

main: func (argc: Int, argv: String*) -> Int {

	if(argc <= 1) {
		printf("rock: no files\n")
		return 1
	}

	unitList := ArrayList<String> new()

	//for(arg: String in Array new(argc - 1, argv + 1)) {
	cursor := argv + 1
	for(i in 0..argc - 1) {
		arg := cursor@
		cursor += 1
		if(arg startsWith("-")) {
			printf("Option: '%s'\n", arg)
		} else {
			unitList add(arg);
			printf("File to compile: '%s'\n", arg)
		}
	}
	
	printf("Finally, files to compile: ")
	for(unit: String in unitList) {
		printf("%s ", unit)
	}
	println()

}
