import structs/[Array, List, ArrayList, Stack]
//import frontend/[Lexer, SourceReader, Token, Help]
import frontend/Help
import parser/Parser
import middle/[FunctionDecl, FunctionCall, StringLiteral, Node]

main: func (argc: Int, argv: String*) -> Int {

    /*
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
	}
    */
    
    Parser parse()
    
	println()

}

stack := Stack<Node> new()

stack_push: func (node: Node) {

    printf("\t\tPushing a %s!!\n", node class name)
    stack push(node)
    
}

stack_pop: func (node: Node) {
    
    stack pop()
    
}




