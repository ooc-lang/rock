import structs/[Array, List, ArrayList, Stack]
import io/File
//import frontend/[Lexer, SourceReader, Token, Help]
import frontend/[Help, Token]
import parser/Parser
import middle/[FunctionDecl, FunctionCall, StringLiteral, Node, Module,
    Statement, Line]
import backend/[CGenerator]
import frontend/compilers/Gcc

main: func (argc: Int, argv: String*) -> Int {

    if(argc <= 1) {
        printf("rock: no files\n")
        return 1
    }

    unitList := ArrayList<String> new()

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
        fullName := unit endsWith(".ooc") ? unit substring(0, unit length() - 4) : unit clone()
        module := Module new(fullName, nullToken)
        stack push(module)
        Parser parse(unit)
        CGenerator new("rock_tmp", module) write() .close()
    }
    
    //compiler := Gcc new()
    //printf("command line = %s\n", compiler getCommandLine())
    
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

stack_pop: func (T: Class) -> Node {
    
    node : Node = stack pop()
    printf("<< pop  %s!!\n", node class name)
    
    if(node class != T) {
        printf("should've been popping a %s, but top is a %s\n", T name, node class name)
        exit(1)
    }
    
    return node
    
}

stack_add: func (node: Node) {
    
    printf("++ add %s, stack = \n", node toString())
    stack_print()
    
    top : Node = stack peek()
    match top class {
        case FunctionCall =>
            call := top as FunctionCall
            call args add(node)
            printf("Just added arg %s to a FunctionCall to %s\n", node toString(), call toString())
        case FunctionDecl =>
            match node class {
                case Line =>
                    top as FunctionDecl body add(node)
                    printf("Adding a line containing a %s\n", node as Line inner toString())
                case =>
                    printf("Expected a line in a FunctionDecl, but got a %s\n", node toString())
            }
        case =>
            printf("Huh oh unknown type '%s' of top element", top toString())
    }
    
}

stack_print: func {
    
    for(elem: Node in stack) {
        printf("\t%s\n", elem toString())
    }
    
}


