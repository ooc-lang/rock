use nagaqueen

import structs/Stack

import nagaqueen/OocListener

import ../middle/ast2/[Module, FuncDecl, Call, Statement]
import ../middle/ast2/tinker/Resolver

AstBuilder: class extends OocListener {

    module: Module
    stack := Stack<Object> new()

    parse: func (path: String) {
        try {
            module = Module new(path substring(0, -5))
            stack push(module)
            super(path)
        } catch (e: Exception) {
            e print()
        }
    }

    /*
     * Stack handling functions
     */
    pop: func <T> (T: Class) -> T {
        v := stack pop()
        if(!v instanceOf?(T)) Exception new("Expected " + T name + ", pop'd " + v class name) throw()
        v
    }

    /*
     * Functions
     */
    onFunctionStart: func (name, doc: CString) {
        fd := FuncDecl new(name toString())
        stack push(fd)
    }

    onFunctionEnd: func -> FuncDecl {
        fd := pop(FuncDecl)
        node := stack peek()
        match node {
            case m: Module =>
                m functions add(fd)
        }
        fd
    }

    onFunctionBody: func {
        // ignore
    }

    /*
     * Function calls
     */
    
    onFunctionCallStart: func (name: CString) {
        stack push(Call new(name toString()))
    }

    onFunctionCallEnd: func -> Call {
        pop(Call)
    }

    /*
     * Statement
     */
    onStatement: func (statement: Statement) {
        node := stack peek()
        match node {
            case fd: FuncDecl =>
                fd body add(statement)
            case =>
                ("Don't know how to react to a statement with " + node class name + " on top of the stack.") println()
        }
    }

}

main: func (argc: Int, argv: CString*) {

    if(argc <= 1) {
        "Usage: ast2-rock FILE" println()
        exit(1)
    }
    
    "Parsing %s" printfln(argv[1])
    builder := AstBuilder new()
    builder parse(argv[1] toString())
    "Done parsing!" println()
    "=================================" println()

    r := Resolver new()
    r modules add(builder module)
    r resolve()
    
}

