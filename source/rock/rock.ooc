import structs/[Array, List, ArrayList, Stack]
//import frontend/[Lexer, SourceReader, Token, Help]
import frontend/[Help, Token]
import parser/Parser
import middle/[FunctionDecl, FunctionCall, StringLiteral, Node, Module,
    Statement, Line]

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
    
    module := Module new("test", nullToken)
    stack push(module)
    Parser parse()
    
	println()

}

stack := Stack<Node> new()

stack_push: func (node: Node) {

    printf(">> push %s!!\n", node class name)
    
    top : Node = stack peek()
    match(node class) {
        case FunctionDecl =>
            fDecl := node as FunctionDecl
            match(top class) {
                case Module =>
                    module := top as Module
                    module addFunction(node)
                    printf("Just added function '%s' to module '%s'\n", fDecl name, module fullName)
                case =>
                    printf("Hey you're trying to add a FunctionDecl to a %s. Wtf?\n", top class name)
            }
        case => printf("Pushing unknown node type %s\n", top class name)
    }
    
    stack push(node)
    
}

stack_pop: func () {
    
    node := stack pop()
    printf("<< pop  %s!!\n", node class name)
    
}

stack_add: func (node: Node) {
    
    printf("++ add %s, stack = \n", node class name)
    stack_print()
    
    top : Node = stack peek()
    match(top class) {
        case FunctionCall =>
            call := top as FunctionCall
            call args add(node)
            printf("Just added arg %s to a FunctionCall to %s\n", node class name, call name)
        case FunctionDecl =>
            top as FunctionDecl body add(Line new(node))
        case =>
            printf("Huh oh unknown type '%s' of top element", top class name)
    }
    
}

stack_print: func {
    
    for(elem: Node in stack) {
        printf("\t%s\n", elem class name)
    }
    
}


