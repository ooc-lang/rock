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
        module includes add(Include new(path isEmpty() ? name : path + name, IncludeModes PATHY))
    }
    
    onImport: unmangled(nq_onImport) func (path, name: String) {
        module imports add(Import new(path isEmpty() ? name : path + name))
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
        peek(CoverDecl) setFromType(type)
    }
    
    onCoverExtends: unmangled(nq_onCoverExtends) func (superType: Type) {
        peek(CoverDecl) superType = superType
    }
    
    onCoverEnd: unmangled(nq_onCoverEnd) func {
        pop(CoverDecl)
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
        peek(ClassDecl) superType = superType
    }
    
    onClassAbstract: unmangled(nq_onClassAbstract) func {
        peek(ClassDecl) isAbstract = true
    }
    
    onClassFinal: unmangled(nq_onClassFinal) func {
        peek(ClassDecl) isFinal = true
    }
    
    onClassEnd: unmangled(nq_onClassEnd) func {
        pop(ClassDecl)
    }
     
    /*
     * Variable declarations
     */
     
    onVarDeclStart: unmangled(nq_onVarDeclStart) func {
        stack push(Stack<VariableDecl> new())
    }
    
    onVarDeclName: unmangled(nq_onVarDeclName) func (name: String) {
        peek(Stack<VariableDecl>) push(VariableDecl new(null, name clone(), Token new(this tokenPos, this module)))
    }
    
    onVarDeclExtern: unmangled(nq_onVarDeclExtern) func (externName: String) {
        peek(Stack<VariableDecl>) peek() setExternName(externName)
    }
    
    onVarDeclExpr: unmangled(nq_onVarDeclExpr) func (expr: Expression) {
        peek(Stack<VariableDecl>) peek() setExpr(expr)
    }
    
    onVarDeclStatic: unmangled(nq_onVarDeclStatic) func {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd setStatic(true)
        }
    }
    
    onVarDeclType: unmangled(nq_onVarDeclType) func (type: Type) {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd type = type
        }
    }
    
    onVarDeclEnd: unmangled(nq_onVarDeclEnd) func -> Stack<VariableDecl> {
        pop(Stack<VariableDecl>)
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
            node as List<Node> add(vd)
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
        oDecl := pop(OperatorDecl)
        peek(Module) addOperator(oDecl)
    }

    /*
     * Functions
     */

    onFunctionStart: unmangled(nq_onFunctionStart) func (name: String) {
        stack push(FunctionDecl new(name clone(), Token new(this tokenPos, this module)))
    }
    
    onFunctionExtern: unmangled(nq_onFunctionExtern) func (externName: String) {
        peek(FunctionDecl) externName = externName clone()
    }
    
    onFunctionAbstract: unmangled(nq_onFunctionAbstract) func {
        peek(FunctionDecl) isAbstract = true
    }
    onFunctionStatic: unmangled(nq_onFunctionStatic) func {
        peek(FunctionDecl) isStatic = true
    }
    onFunctionInline: unmangled(nq_onFunctionInline) func {
        peek(FunctionDecl) isInline = true
    }
    
    onFunctionFinal: unmangled(nq_onFunctionFinal) func {
        peek(FunctionDecl) isFinal = true
    }
    
    onFunctionSuffix: unmangled(nq_onFunctionSuffix) func (suffix: String) {
        peek(FunctionDecl) suffix = suffix clone()
    }
    
    onFunctionArgsStart: unmangled(nq_onFunctionArgsStart) func {
        stack push(peek(FunctionDecl) args)
    }
    
    onFunctionArgsEnd: unmangled(nq_onFunctionArgsEnd) func {
        pop(ArrayList<Argument>)
    }
    
    onFunctionReturnType: unmangled(nq_onFunctionReturnType) func (type: Type) {
        peek(FunctionDecl) returnType = type
    }
    
    onFunctionEnd: unmangled(nq_onFunctionEnd) func -> FunctionDecl {
        fDecl := pop(FunctionDecl)
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
        stack push(FunctionCall new(name clone(), Token new(this tokenPos, this module)))
    }
    
    onFunctionCallArg: unmangled(nq_onFunctionCallArg) func (expr: Expression) {
        peek(FunctionCall) args add(expr)
    }
    
    onFunctionCallEnd: unmangled(nq_onFunctionCallEnd) func -> FunctionCall {
        pop(FunctionCall)
    }
    
    onFunctionCallExpr: unmangled(nq_onFunctionCallExpr) func (call: FunctionCall, expr: Expression) {
        call expr = expr
    }
    
    /*
     * Literals
     */
    
    onStringLiteral: unmangled(nq_onStringLiteral) func (text: String) -> StringLiteral {
        StringLiteral new(text clone(), Token new(this tokenPos, this module))
    }
    
    // statement
    onStatement: unmangled(nq_onStatement) func (stmt: Statement) {
        node := stack peek() as Node
        if(node instanceOf(VariableDecl)) {
            gotVarDecl(node)
            return
        } else if(stmt instanceOf(Stack<VariableDecl>)) {
            stack : Stack<VariableDecl> = stmt
            if(stack T inheritsFrom(VariableDecl)) {
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
            case node instanceOf(ControlStatement) =>
                cStmt : ControlStatement = node
                cStmt body add(stmt)
        }
    }
    
    onArrayAccess: unmangled(nq_onArrayAccess) func (array, index: Expression) -> ArrayAccess {
        ArrayAccess new(array, index, Token new(this tokenPos, this module))
    }
    
    // return
    onReturn: unmangled(nq_onReturn) func (expr: Expression) -> Return {
        Return new(expr, Token new(this tokenPos, this module))
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
        peek(List<Node>) add(VarArg new(Token new(this tokenPos, this module)))
    }

    onTypeArg: unmangled(nq_onTypeArg) func (type: Type) {
        // TODO: add check for extern function (TypeArgs are illegal in non-extern functions.)
        peek(List<Node>) add(Argument new(type, "", Token new(this tokenPos, this module)))
    }
    
    /*
     * Match & case
     */
    onMatchStart: unmangled(nq_onMatchStart) func {
        stack push(Match new(Token new(this tokenPos, this module)))
    }
    
    onMatchExpr: unmangled(nq_onMatchExpr) func (v:Expression) {
        peek(Match) setExpr(v)
    }
    
    onMatchEnd: unmangled(nq_onMatchEnd) func -> Match {
        pop(Match)
    }

    onCaseStart: unmangled(nq_onCaseStart) func {
        stack push(Case new(Token new(this tokenPos, this module)))
    }
    
    onCaseExpr: unmangled(nq_onCaseExpr) func (v:Expression) {
        peek(Case) setExpr(v)
    }
    
    onCaseEnd: unmangled(nq_onCaseEnd) func {
        pop(Case)
    }
    
    nq_onBreak: unmangled func -> FlowControl {
        FlowControl new(FlowActions _break, Token new(this tokenPos, this module))
    }

    nq_onContinue: unmangled func -> FlowControl {
        FlowControl new(FlowActions _continue, Token new(this tokenPos, this module))
    }

    nq_onEquals: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes equal, Token new(this tokenPos, this module))
    }
    nq_onNotEquals: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes notEqual, Token new(this tokenPos, this module))
    }
    nq_onLessThan: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes smallerThan, Token new(this tokenPos, this module))
    }
    nq_onMoreThan: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes greaterThan, Token new(this tokenPos, this module))
    }
    nq_onCmp: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes compare, Token new(this tokenPos, this module))
    }

    nq_onLessThanOrEqual: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes smallerOrEqual, Token new(this tokenPos, this module))
    }
    nq_onMoreThanOrEqual: unmangled func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes greaterOrEqual, Token new(this tokenPos, this module))
    }

    nq_onIntLiteral: unmangled func (value: String) -> IntLiteral {
        IntLiteral new(value toLLong(), Token new(this tokenPos, this module))
    }

    nq_onFloatLiteral: unmangled func (value: String) -> IntLiteral {
        FloatLiteral new(value toFloat(), Token new(this tokenPos, this module))
    }

    nq_onBoolLiteral: unmangled func (value: Bool) -> BoolLiteral {
        BoolLiteral new(value, Token new(this tokenPos, this module))
    }

    nq_onNull: unmangled func -> NullLiteral {
        NullLiteral new(Token new(this tokenPos, this module))
    }

    nq_onTernary: unmangled func (condition, ifTrue, ifFalse: Expression) -> Ternary {
        Ternary new(condition, ifTrue, ifFalse, Token new(this tokenPos, this module))
    }

    nq_onAssignAdd: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes addAss, Token new(this tokenPos, this module))
    }

    nq_onAssignSub: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes subAss, Token new(this tokenPos, this module))
    }

    nq_onAssignMul: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mulAss, Token new(this tokenPos, this module))
    }

    nq_onAssignDiv: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes divAss, Token new(this tokenPos, this module))
    }

    nq_onAssignAnd: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bAndAss, Token new(this tokenPos, this module))
    }

    nq_onAssignOr: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bOrAss, Token new(this tokenPos, this module))
    }

    nq_onAssignXor: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bXorAss, Token new(this tokenPos, this module))
    }

    nq_onAssign: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes ass, Token new(this tokenPos, this module))
    }
        
    nq_onAssignLeftShift: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes lshiftAss, Token new(this tokenPos, this module))
    }

    nq_onAssignRightShift: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes rshiftAss, Token new(this tokenPos, this module))
    }

    nq_onAdd: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes add, Token new(this tokenPos, this module))
    }

    nq_onSub: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes sub, Token new(this tokenPos, this module))
    }

    nq_onMod: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mod, Token new(this tokenPos, this module))
    }

    nq_onMul: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mul, Token new(this tokenPos, this module))
    }

    nq_onDiv: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes div, Token new(this tokenPos, this module))
    }

    nq_onRangeLiteral: unmangled func (left, right: Expression) -> RangeLiteral {
        RangeLiteral new(left, right, Token new(this tokenPos, this module))
    }

    nq_onBinaryLeftShift: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes lshift, Token new(this tokenPos, this module))
    }

    nq_onBinaryRightShift: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes rshift, Token new(this tokenPos, this module))
    }

    nq_onLogicalOr: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes or, Token new(this tokenPos, this module))
    }

    nq_onLogicalAnd: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes and, Token new(this tokenPos, this module))
    }

    nq_onBinaryOr: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bOr, Token new(this tokenPos, this module))
    }

    nq_onBinaryXor: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bXor, Token new(this tokenPos, this module))
    }

    nq_onBinaryAnd: unmangled func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bAnd, Token new(this tokenPos, this module))
    }

    nq_onLogicalNot: unmangled func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes logicalNot, Token new(this tokenPos, this module))
    }

    nq_onBinaryNot: unmangled func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes binaryNot, Token new(this tokenPos, this module))
    }

    nq_onUnaryMinus: unmangled func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes unaryMinus, Token new(this tokenPos, this module))
    }

    nq_onParenthesis: unmangled func (inner: Expression) -> Parenthesis {
        Parenthesis new(inner, Token new(this tokenPos, this module))
    }
    
    peek: func <T> (T: Class) -> T {
        node := stack peek() as Node
        if(!node instanceOf(T)) {
            Exception new(This, "Should've peek'd a %s, but peek'd a %s" format(T name, node class name)) throw()
        }
        return node
    }
    
    pop: func <T> (T: Class) -> T {
        node := stack pop() as Node
        if(!node instanceOf(T)) {
            Exception new(This, "Should've pop'd a %s, but pop'd a %s" format(T name, node class name)) throw()
        }
        return node
    }

}

// position in stream handling
nq_setTokenPositionPointer: unmangled func (this: AstBuilder, tokenPos: Int*) { this tokenPos = tokenPos }

// string handling
nq_StringClone: unmangled func (string: String) -> String             { string clone() }

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

