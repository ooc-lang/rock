import structs/[Array, List, ArrayList]
import frontend/[Tokenizer, SourceReader, Token]

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
		printf("%s\n", unit)
		tokenizer := Tokenizer new() .setDebug(true)
		sReader := SourceReader getReaderFromPath(unit)
		list := tokenizer parse(sReader)
		i := 1
		for(token: Token in list) {
			//printf("Token #%d (type %d = %s, %zu:%zu)\n", i, token type, token toString(), token start, token length)
			printf("%s ", token toString(sReader));
			i += 1
		}
		("Got " + list size() + " tokens.") println()
	}
	println()

}
