use nagaqueen

import structs/Stack

import nagaqueen/OocListener

import ../middle/ast2/[Module, FuncDecl, Call, Statement, Type, Expression,
    Var, Access, StringLit]
import ../middle/ast2/tinker/Resolver

/**
 * Used to parse multi-vars declarations, ie.
 * 
 *   a, b, c: Int
 */
VarStack: class {

    type: Type
    vars := Stack<Var> new()

}

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

    peek: func <T> (T: Class) -> T {
        v := stack peek()
        if(!v instanceOf?(T)) Exception new("Expected " + T name + ", peek'd " + v class name) throw()
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

    onFunctionArgsStart: func {
        stack push(peek(FuncDecl) args)
    }

    onFunctionArgsEnd: func {
        stack pop() // args
    }
    

    onFunctionBody: func {
        // ignore
    }

    onFunctionAttr: func (f: FuncAttributes, value: CString = null) {
        fd := peek(FuncDecl)
        match f {
            case FuncAttributes _extern =>
                fd externName = (value ? value : "")
            case =>
                "Unknown function attribute %d" printfln(f)
        }
    }

    onFunctionReturnType: func (returnType: Type) {
        peek(FuncDecl) retType = returnType
    }

    /*
     * Function calls
     */
    
    onFunctionCallStart: func (name: CString) {
        stack push(Call new(name toString()))
    }

    onFunctionCallArg: func (arg: Expression) {
        peek(Call) args add(arg)
    }

    onFunctionCallEnd: func -> Call {
        pop(Call)
    }

    /* Variable declarations */

    onVarDeclStart: func {
        stack push(VarStack new())
    }

    onVarDeclEnd: func -> Object {
        pop(VarStack)
    }


    onVarDeclName: func (name, doc: CString) {
        vStack := peek(VarStack)
        vStack vars push(Var new(name toString()))
    }

    onVarDeclExpr: func (expr: Expression) {
        peek(VarStack) vars peek() expr = expr
    }

    onVarDeclType: func (type: Type) {
        peek(VarStack) vars each(|v|
            v _type = type
        )
    }

    /* Types */

    onTypeNew: func (name: CString) -> Type {
        BaseType new(name toString())
    }

    /* Various expression/statements */
    
    onStringLiteral: func (text: CString) -> StringLit {
        StringLit new(text toString())
    }

    onVarAccess: func (expr: Expression, name: CString) -> Access {
        Access new(expr, name toString())
    }

    /*
     * Statement
     */
    onStatement: func (statement: Statement) {
        match statement {
            case vStack: VarStack =>
                vStack vars each(|v|
                    ("Popping var " + v toString())
                    onStatement(v)
                )
                return
        }
        
        node := stack peek()
        match node {
            case fd: FuncDecl =>
                fd body add(statement)
            case =>
                ("Don't know how to react to a statement with " + node class name + " on top of the stack.") println()
        }
    }

}

