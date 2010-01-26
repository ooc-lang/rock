import io/File

import structs/[Array, ArrayList, List, Stack, HashMap]

import ../frontend/[Token, BuildParams]
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Include, Import,
    Type, Expression, Return, VariableAccess, Cast, If, Else, ControlStatement,
    Comparison, IntLiteral, FloatLiteral, Ternary, BinaryOp, BoolLiteral,
    NullLiteral, Argument, Parenthesis, AddressOf, Dereference, Foreach,
    OperatorDecl, RangeLiteral, UnaryOp, ArrayAccess, Match, FlowControl,
    While]

nq_parse: extern proto func (AstBuilder, String) -> Int

AstBuilder: class {

    cache := static HashMap<Module> new()
    
    params : BuildParams
    modulePath : String
    module : Module
    stack : Stack<Node>
    
    tokenPos : Int*

    init: func (=modulePath, =module, =params) {
        
        if(params verbose) {
            printf("- Parsing %s (for module %s)\n", modulePath, module fullName)
        }
        cache put(modulePath, module)
        
        stack = Stack<Node> new()
        stack push(module)
        result := nq_parse(this, modulePath)
        if(result == -1) {
            Exception new(This, "File " +modulePath + " not found") throw()
        }
        
        if(params includeLang && !module fullName startsWith("/")) {
            addLangImports()
        }
        parseImports()
        
    }
    
    addLangImports: func {
    
        //printf("Should add lang imports\n")
        paths := params sourcePath getRelativePaths("lang")
        for(path in paths) {
            //printf("Considering path %s\n", path)
            if(path endsWith(".ooc")) {
                impName := path substring(0, path length() - 4)
                if(impName != module fullName) {
                    //printf("Adding import %s to %s\n", impName, module fullName)
                    module imports add(Import new(impName))
                }
            }
        }
        
    }
    
    parseImports: func {
        
        for(imp: Import in module imports) {
            path := imp path + ".ooc"
            if(path startsWith("..")) {
                //path = FileUtils resolveRedundancies(File new(module getParentPath(), path)) path
            }
            
            impElement := params sourcePath getElement(path)
            impPath := params sourcePath getFile(path)
            if(!impPath) {
                path = module getParentPath() + "/" + path
                impElement = params sourcePath getElement(path)
                impPath = params sourcePath getFile(path)
                if(impPath == null) {
                    //throw new OocCompilationError(imp, module, "Module not found in sourcepath: "+imp path);
                    Exception new(This, "Module not found in sourcepath: " + imp path) throw()
                }
            }
            
            //println("Trying to get "+impPath path+" from cache")
            cached : Module = null
            cached = cache get(impPath path)
            
            //if(!cached || File new(impPath path) lastModified() > cached lastModified) {
            if(!cached) {
                if(cached) {
                    println(path+" has been changed, recompiling...");
                }
                cached = Module new(path substring(0, path length() - 4), impElement path, Token new(this tokenPos, this module))
                imp setModule(cached)
                This new(impPath path, cached, params)
            }
            imp setModule(cached)
        }
        
    }
    
    printCache: func {
        printf("==== Cache ====\n")
        for(key in cache keys) {
            printf("cache %s => %s\n", key, cache get(key) fullName)
        }
        printf("===============\n")
    }
    
    error: func (errorID: Int, message: String, index: Int) {
        Token new(index, 1, module) throwError(message)
    }
    
    onInclude: unmangled(nq_onInclude) func (path, name: String) {
        inc := Include new(path isEmpty() ? name : path + name, IncludeModes PATHY)
        module includes add(inc)
        //printf("Got include %s\n", inc path)
    }
    
    onImport: unmangled(nq_onImport) func (path, name: String) {
        imp := Import new(path isEmpty() ? name : path + name)
        module imports add(imp)
        //printf("Got Import %s\n", imp path)
    }
    
    /*
     * Covers
     */
    
    onCoverStart: unmangled(nq_onCoverStart) func (name: String) {
        cDecl := CoverDecl new(name clone(), null, Token new(this tokenPos, this module))
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onCoverFromType: unmangled(nq_onCoverFromType) func (type: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl setFromType(type)
    }
    
    onCoverExtends: unmangled(nq_onCoverExtends) func (superType: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl superType = superType
    }
    
    onCoverEnd: unmangled(nq_onCoverEnd) func {
        node : Node = stack pop()
    }
    
    /*
     * Classes
     */
    
    onClassStart: unmangled(nq_onClassStart) func (name: String) {
        cDecl := ClassDecl new(name clone(), null, Token new(this tokenPos, this module))
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onClassExtends: unmangled(nq_onClassExtends) func (superType: Type) {
        cDecl : ClassDecl = stack peek()
        cDecl superType = superType
    }
    
    onClassAbstract: unmangled(nq_onClassAbstract) func {
        cDecl : ClassDecl = stack peek()
        cDecl isAbstract = true
    }
    
    onClassFinal: unmangled(nq_onClassFinal) func {
        cDecl : ClassDecl = stack peek()
        cDecl isFinal = true
    }
    
    onClassEnd: unmangled(nq_onClassEnd) func {
        node : Node = stack pop()
    }
     
    /*
     * Variable declarations
     */
     
    onVarDeclStart: unmangled(nq_onVarDeclStart) func {
        stack push(Stack<VariableDecl> new())
    }
    
    onVarDeclName: unmangled(nq_onVarDeclName) func (name: String) {
        vds : Stack<VariableDecl> = stack peek()
        vds push(VariableDecl new(null, name clone(), Token new(this tokenPos, this module)))
    }
    
    onVarDeclExtern: unmangled(nq_onVarDeclExtern) func (externName: String) {
        vds : Stack<VariableDecl> = stack peek()
        vds peek() setExternName(externName)
    }
    
    onVarDeclExpr: unmangled(nq_onVarDeclExpr) func (expr: Expression) {
        vds : Stack<VariableDecl> = stack peek()
        vds peek() setExpr(expr)
    }
    
    onVarDeclStatic: unmangled(nq_onVarDeclStatic) func {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            vd setStatic(true)
        }
    }
    
    onVarDeclType: unmangled(nq_onVarDeclType) func (type: Type) {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            vd type = type
        }
    }
    
    onVarDeclEnd: unmangled(nq_onVarDeclEnd) func -> Stack<VariableDecl> {
        vds : Stack<VariableDecl> = stack pop()
        return vds
    }
    
    onVarDeclAssign: unmangled(nq_onVarDeclAssign) func (acc: VariableAccess, isConst: Bool, expr: Expression) -> VariableDecl {
        if(!acc instanceOf(VariableAccess)) {
            Exception new(AstBuilder, "Expected a VariableAccess as a left-hand-side of a decl-assign, but got a " + acc toString()) throw()
        }
        vDecl := VariableDecl new(null, acc name, expr, Token new(this tokenPos, this module))
        vDecl isConst = isConst
        return vDecl
    }
    
    gotVarDecl: func (vd: VariableDecl) {
        node : Node = stack peek()
        if(node instanceOf(TypeDecl)) {
            tDecl := node as TypeDecl
            tDecl addVariable(vd)
        } else if(node instanceOf(List)) {
            list : List<Node> = node
            //printf("Adding variableDecl %s to a %s\n", vd toString(), list class name)
            list add(vd)
        } else {
            onStatement(vd)
        }
    }
    
    /*
     * Types
     */
    
    onTypeNew: unmangled(nq_onTypeNew) func (name: String) -> Type   {
        BaseType new(name clone() trim(), Token new(this tokenPos, this module))
    }
    
    onTypePointer: unmangled(nq_onTypePointer) func (type: Type) -> Type {
        PointerType new(type, Token new(this tokenPos, this module))
    }
    
    onTypeGenericArgument: unmangled(nq_onTypeGenericArgument) func (type: Type, name: String) {
        type addTypeArgument(VariableAccess new(name clone(), Token new(this tokenPos, this module)))
    }
    
    onFuncTypeNew: unmangled(nq_onFuncTypeNew) func -> Type {
        FuncType new(Token new(this tokenPos, this module))
    }
    
    /*
     * Operator overloads
     */

    onOperatorStart: unmangled(nq_onOperatorStart) func (symbol: String) {
        oDecl := OperatorDecl new(symbol clone() trim(), Token new(this tokenPos, this module))
        fDecl := FunctionDecl new("", Token new(this tokenPos, this module))
        oDecl setFunctionDecl(fDecl)
        stack push(oDecl)
        stack push(fDecl)
    }
    
    onOperatorEnd: unmangled(nq_onOperatorEnd) func {
        oDecl : OperatorDecl = stack pop()
        node : Node = stack peek()
        if(node == module) {
            module addOperator(oDecl)
        } else {
            oDecl token throwError("Unexpected operator overload here!")
        }
    }

    /*
     * Functions
     */

    onFunctionStart: unmangled(nq_onFunctionStart) func (name: String) {
        fDecl := FunctionDecl new(name clone(), Token new(this tokenPos, this module))
        stack push(fDecl)
    }
    
    onFunctionExtern: unmangled(nq_onFunctionExtern) func (externName: String) {
        fDecl : FunctionDecl = stack peek()
        fDecl externName = externName clone()
    }
    
    onFunctionAbstract: unmangled(nq_onFunctionAbstract) func {
        fDecl : FunctionDecl = stack peek()
        fDecl isAbstract = true
    }
    onFunctionStatic: unmangled(nq_onFunctionStatic) func {
        fDecl : FunctionDecl = stack peek()
        fDecl isStatic = true
    }
    onFunctionInline: unmangled(nq_onFunctionInline) func {
        fDecl : FunctionDecl = stack peek()
        fDecl isInline = true
    }
    
    onFunctionFinal: unmangled(nq_onFunctionFinal) func {
        fDecl : FunctionDecl = stack peek()
        fDecl isFinal = true
    }
    
    onFunctionSuffix: unmangled(nq_onFunctionSuffix) func (suffix: String) {
        fDecl : FunctionDecl = stack peek()
        fDecl suffix = suffix clone()
    }
    
    onFunctionArgsStart: unmangled(nq_onFunctionArgsStart) func {
        fDecl : FunctionDecl = stack peek()
        stack push(fDecl args)
    }
    
    onFunctionArgsEnd: unmangled(nq_onFunctionArgsEnd) func {
        node : Node = stack pop()
        //printf("Wanted to pop an ArrayList, got a %s\n", node class name)
    }
    
    onFunctionReturnType: unmangled(nq_onFunctionReturnType) func (type: Type) {
        fDecl : FunctionDecl = stack peek()
        fDecl returnType = type
    }
    
    onFunctionEnd: unmangled(nq_onFunctionEnd) func -> FunctionDecl {
        fDecl : FunctionDecl = stack pop()
        node : Node = stack peek()
        if(node == module) {
            module addFunction(fDecl)
        } else if(node instanceOf(TypeDecl)) {
            tDecl: TypeDecl = node
            tDecl addFunction(fDecl)
        } else {
            //printf("^^^^^^^^ Unexpected function %s (peek is a %s)\n", fDecl name, node class name)
        }
        return fDecl
    }
    
    /*
     * Function calls
     */
    
    onFunctionCallStart: unmangled(nq_onFunctionCallStart) func (name: String) {
        fCall := FunctionCall new(name clone(), Token new(this tokenPos, this module))
        stack push(fCall)
    }
    
    onFunctionCallArg: unmangled(nq_onFunctionCallArg) func (expr: Expression) {
        fCall : FunctionCall = stack peek()
        fCall args add(expr)
        //printf("Function call to %s got arg %p\n", fCall name, expr)
    }
    
    onFunctionCallEnd: unmangled(nq_onFunctionCallEnd) func -> FunctionCall {
        node : Node = stack pop()
        //printf("Wanted to pop a FunctionCall, got a %s\n", node class name)
        return node as FunctionCall
    }
    
    onFunctionCallExpr: unmangled(nq_onFunctionCallExpr) func (call: FunctionCall, expr: Expression) {
        //printf("Call to %s became a member call of expression %s\n", call toString(), expr toString())
        call expr = expr
    }
    
    /*
     * Literals
     */
    
    onStringLiteral: unmangled(nq_onStringLiteral) func (text: String) -> StringLiteral {
        sl := StringLiteral new(text clone(), Token new(this tokenPos, this module))
        //printf("Got string literal %s\n", sl toString())
        return sl
    }
    
    // statement
    onStatement: unmangled(nq_onStatement) func (stmt: Statement) {
        node : Node = stack peek()
        if(node instanceOf(VariableDecl)) {
            //"Got varDecl %s" format(node toString()) println()
            gotVarDecl(node)
            return
        } else if(stmt instanceOf(Stack<VariableDecl>)) {
            stack : Stack<VariableDecl> = stmt
            if(stack T inheritsFrom(VariableDecl)) {
                //"Got a stack of variableDecls" println()
                for(vd in stack) {
                    gotVarDecl(vd)
                }
                return
            }
        }
        match {
            case node instanceOf(FunctionDecl) =>
                fDecl : FunctionDecl = node
                fDecl body add(stmt)
                //printf("Added line to function decl %s\n", fDecl name)
            case node instanceOf(ControlStatement) =>
                cStmt : ControlStatement = node
                cStmt body add(stmt)
                //printf("Added line to control statement %s\n", cStmt toString())
        }
    }
    
    onArrayAccess: unmangled(nq_onArrayAccess) func (array, index: Expression) -> ArrayAccess {
        return ArrayAccess new(array, index, Token new(this tokenPos, this module))
    }
    
    // return
    onReturn: unmangled(nq_onReturn) func (expr: Expression) -> Return {
        ret := Return new(expr, Token new(this tokenPos, this module))
        //printf("Got return %p with expr %s (%p)\n", ret, expr ? expr toString() : "(nil)", expr)
        return ret
    }
    
    // variable access
    onVarAccess: unmangled(nq_onVarAccess) func (expr: Expression, name: String) -> VariableAccess {
        return VariableAccess new(expr, name clone(), Token new(this tokenPos, this module))
    }
    
    // cast
    onCast: unmangled(nq_onCast) func (expr: Expression, type: Type) -> Cast {
        return Cast new(expr, type, Token new(this tokenPos, this module))
    }
    
    // if
    onIfStart: unmangled(nq_onIfStart) func (condition: Expression) {
        stack push(If new(condition, Token new(this tokenPos, this module)))
    }
    
    onIfEnd: unmangled(nq_onIfEnd) func -> If {
        if1 : If = stack pop()
        //("Wanted to pop an If, got a " + if1 class name) println()
        return if1
    }
    
    // else
    onElseStart: unmangled(nq_onElseStart) func {
        stack push(Else new(Token new(this tokenPos, this module)))
    }
    
    onElseEnd: unmangled(nq_onElseEnd) func -> Else {
        else1 : Else = stack pop()
        //("Wanted to pop an Else, got a " + else1 class name) println()
        return else1
    }
    
    // foreach
    onForeachStart: unmangled(nq_onForeachStart) func (decl, collec: Expression) {
        if(decl instanceOf(Stack)) {
            decl = decl as Stack<VariableDecl> pop()
        }
        stack push(Foreach new(decl, collec, Token new(this tokenPos, this module)))
    }
    
    onForeachEnd: unmangled(nq_onForeachEnd) func -> Foreach {
        foreach1 : Foreach = stack pop()
        //("Wanted to pop an Foreach, got a " + foreach1 class name) println()
        return foreach1
    }
    
    // while
    onWhileStart: unmangled(nq_onWhileStart) func (condition: Expression) {
        stack push(While new(condition, Token new(this tokenPos, this module)))
    }
    
    onWhileEnd: unmangled(nq_onWhileEnd) func -> While {
        whyle : While = stack pop()
        //("Wanted to pop an While, got a " + whyle class name) println()
        return whyle
    }
    
    /*
     * Arguments
     */
    onVarArg: unmangled(nq_onVarArg) func {
        vararg := VarArg new(Token new(this tokenPos, this module))
        node : Node = this stack peek()
        if(node instanceOf(List)) {
            list : List<Node> = node
            //printf("Adding vararg %s to a %s\n", vararg toString(), list class name)
            list add(vararg)
        } else {
            vararg token throwError("Unexpected vararg! parent is a %s" format(node class name))
        }
    }

    onTypeArg: unmangled(nq_onTypeArg) func (type: Type) {
        typeArg := Argument new(type, "", Token new(this tokenPos, this module))
        // TODO: add check for extern function (TypeArgs are illegal in non-extern functions.)
        node : Node = this stack peek()
        if(node instanceOf(List)) {
            list : List<Node> = node
            //printf("Adding typeArg %s to a %s\n", typeArg toString(), list class name)
            list add(typeArg)
        } else {
            typeArg token throwError("Unexpected typeArg! parent is a %s" format(node class name))
        }
    }
    
    peek: func <T> (T: Class) -> T {
        node := stack peek()
    }

}

// position in stream handling
nq_setTokenPositionPointer: unmangled func (this: AstBuilder, tokenPos: Int*) { this tokenPos = tokenPos }

// string handling
nq_StringClone: unmangled func (string: String) -> String             { string clone() }

nq_onMatchStart: unmangled func (this: AstBuilder)               { this stack push(Match new(Token new(this tokenPos, this module))) }
nq_onMatchExpr:  unmangled func (this: AstBuilder, v:Expression) { m := this stack peek() as Match; m setExpr(v) }
nq_onMatchEnd:   unmangled func (this: AstBuilder) -> Match {
    m : Node = this stack pop()
    if(!m instanceOf(Match)) {
        Exception new(AstBuilder, "Should've popped a Match, but popped a %s instead!" format(m class name)) throw()
    }
    m
}

nq_onCaseStart: unmangled func (this: AstBuilder)               { this stack push(Case new(Token new(this tokenPos, this module))) }
nq_onCaseExpr:  unmangled func (this: AstBuilder, v:Expression) { c := this stack peek() as Case; c setExpr(v) }
nq_onCaseEnd:   unmangled func (this: AstBuilder) {
    c : Node = this stack pop()
    if(!c instanceOf(Case)) {
        Exception new(AstBuilder, "Should've popped a Case, but popped a %s instead!" format(c class name)) throw()
    }
    m := this stack peek() as Match
    m addCase(c)
}

nq_onBreak:    unmangled func (this: AstBuilder) -> FlowControl { FlowControl new(FlowActions _break,    Token new(this tokenPos, this module)) }
nq_onContinue: unmangled func (this: AstBuilder) -> FlowControl { FlowControl new(FlowActions _continue, Token new(this tokenPos, this module)) }

nq_onEquals: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes equal, Token new(this tokenPos, this module))
}
nq_onNotEquals: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes notEqual, Token new(this tokenPos, this module))
}
nq_onLessThan: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes smallerThan, Token new(this tokenPos, this module))
}
nq_onMoreThan: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes greaterThan, Token new(this tokenPos, this module))
}
nq_onCmp: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes compare, Token new(this tokenPos, this module))
}

nq_onLessThanOrEqual: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes smallerOrEqual, Token new(this tokenPos, this module))
}
nq_onMoreThanOrEqual: unmangled func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes greaterOrEqual, Token new(this tokenPos, this module))
}

nq_onIntLiteral: unmangled func (this: AstBuilder, value: String) -> IntLiteral {
    return IntLiteral new(value toLLong(), Token new(this tokenPos, this module))
}

nq_onFloatLiteral: unmangled func (this: AstBuilder, value: String) -> IntLiteral {
    return FloatLiteral new(value toFloat(), Token new(this tokenPos, this module))
}

nq_onBoolLiteral: unmangled func (this: AstBuilder, value: Bool) -> BoolLiteral {
    return BoolLiteral new(value, Token new(this tokenPos, this module))
}

nq_onNull: unmangled func (this: AstBuilder) -> NullLiteral {
    return NullLiteral new(Token new(this tokenPos, this module))
}

nq_onTernary: unmangled func (this: AstBuilder, condition, ifTrue, ifFalse: Expression) -> Ternary {
    return Ternary new(condition, ifTrue, ifFalse, Token new(this tokenPos, this module))
}

nq_onAssignAdd: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes addAss, Token new(this tokenPos, this module))
}

nq_onAssignSub: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes subAss, Token new(this tokenPos, this module))
}

nq_onAssignMul: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mulAss, Token new(this tokenPos, this module))
}

nq_onAssignDiv: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes divAss, Token new(this tokenPos, this module))
}

nq_onAssignAnd: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bAndAss, Token new(this tokenPos, this module))
}

nq_onAssignOr: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bOrAss, Token new(this tokenPos, this module))
}

nq_onAssignXor: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bXorAss, Token new(this tokenPos, this module))
}

nq_onAssign: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes ass, Token new(this tokenPos, this module))
}
    
nq_onAssignLeftShift: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes lshiftAss, Token new(this tokenPos, this module))
}

nq_onAssignRightShift: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes rshiftAss, Token new(this tokenPos, this module))
}

nq_onAdd: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes add, Token new(this tokenPos, this module))
}

nq_onSub: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes sub, Token new(this tokenPos, this module))
}

nq_onMod: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mod, Token new(this tokenPos, this module))
}

nq_onMul: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mul, Token new(this tokenPos, this module))
}

nq_onDiv: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes div, Token new(this tokenPos, this module))
}

nq_onRangeLiteral: unmangled func (this: AstBuilder, left, right: Expression) -> RangeLiteral {
    return RangeLiteral new(left, right, Token new(this tokenPos, this module))
}

nq_onBinaryLeftShift: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes lshift, Token new(this tokenPos, this module))
}

nq_onBinaryRightShift: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes rshift, Token new(this tokenPos, this module))
}

nq_onLogicalOr: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes or, Token new(this tokenPos, this module))
}

nq_onLogicalAnd: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes and, Token new(this tokenPos, this module))
}

nq_onBinaryOr: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bOr, Token new(this tokenPos, this module))
}

nq_onBinaryXor: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bXor, Token new(this tokenPos, this module))
}

nq_onBinaryAnd: unmangled func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bAnd, Token new(this tokenPos, this module))
}

nq_onLogicalNot: unmangled func (this: AstBuilder, inner: Expression) -> UnaryOp {
    return UnaryOp new(inner, UnaryOpTypes logicalNot, Token new(this tokenPos, this module))
}

nq_onBinaryNot: unmangled func (this: AstBuilder, inner: Expression) -> UnaryOp {
    return UnaryOp new(inner, UnaryOpTypes binaryNot, Token new(this tokenPos, this module))
}

nq_onUnaryMinus: unmangled func (this: AstBuilder, inner: Expression) -> UnaryOp {
    return UnaryOp new(inner, UnaryOpTypes unaryMinus, Token new(this tokenPos, this module))
}

nq_onParenthesis: unmangled func (this: AstBuilder, inner: Expression) -> Parenthesis {
    return Parenthesis new(inner, Token new(this tokenPos, this module))
}

nq_onGenericArgument: unmangled func (this: AstBuilder, name: String) {
    
    node : Node = this stack peek()
    printf("======= Got generic argument %s, and node is a %s\n", name, node class name)
        
    token := Token new(this tokenPos, this module)
    vDecl := VariableDecl new(BaseType new("Class", token), name clone(), token)
    if(!node addTypeArgument(vDecl)) {
        token throwError("Unexpected type argument in a %s declaration!" format(node class name))
    }
    
}

nq_onAddressOf:   unmangled func (this: AstBuilder, inner: Expression) -> AddressOf   { return AddressOf   new(inner, Token new(this tokenPos, this module)) }
nq_onDereference: unmangled func (this: AstBuilder, inner: Expression) -> Dereference { return Dereference new(inner, Token new(this tokenPos, this module)) }

nq_error: unmangled func (this: AstBuilder, errorID: Int, message: String, index: Int) { this error(errorID, message, index) }

