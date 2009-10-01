import structs/[Array, List, ArrayList]
import frontend/[Lexer, SourceReader, Token, Help]

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
		match {
			case arg startsWith("-") =>
				match {
					case arg equals("--help-none") =>
						Help printHelpNone()
					case =>
					("Unknown compiler option " + arg) println()
				}
			case =>
				unitList add(arg);
		}
	}
	
	for(unit: String in unitList) {
		printf("%s\n", unit)
		tokenizer := Lexer new() .setDebug(true)
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
