import io/File

import structs/[Array, ArrayList, List, Stack, HashMap]

import ../frontend/[Token, BuildParams]
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Include, Import,
    Type, Expression, Return, VariableAccess, Cast, If, Else, ControlStatement,
    Comparison, IntLiteral, FloatLiteral, Ternary, BinaryOp, BoolLiteral,
    NullLiteral, Argument, Parenthesis, AddressOf, Dereference, Foreach,
    OperatorDecl, RangeLiteral, UnaryOp, ArrayAccess, Match, FlowControl,
    While, CharLiteral]

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
        cDecl := CoverDecl new(name clone(), token())
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onCoverFromType: unmangled(nq_onCoverFromType) func (type: Type) {
        peek(CoverDecl) setFromType(type)
    }
    
    onCoverExtends: unmangled(nq_onCoverExtends) func (superType: Type) {
        peek(CoverDecl) setSuperType(superType)
    }
    
    onCoverEnd: unmangled(nq_onCoverEnd) func {
        pop(CoverDecl)
    }
    
    /*
     * Classes
     */
    
    onClassStart: unmangled(nq_onClassStart) func (name: String) {
        cDecl := ClassDecl new(name clone(), token())
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onClassExtends: unmangled(nq_onClassExtends) func (superType: Type) {
        peek(ClassDecl) setSuperType(superType)
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
        peek(Stack<VariableDecl>) push(VariableDecl new(null, name clone(), token()))
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
        vDecl := VariableDecl new(null, acc name, expr, token())
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
        BaseType new(name clone() trim(), token())
    }
    
    onTypePointer: unmangled(nq_onTypePointer) func (type: Type) -> Type {
        PointerType new(type, token())
    }
    
    onTypeGenericArgument: unmangled(nq_onTypeGenericArgument) func (type: Type, name: String) {
        printf("Type %s just had typeArgument %s!\n", type toString(), name)
        type addTypeArgument(VariableAccess new(name clone(), token()))
    }
    
    onFuncTypeNew: unmangled(nq_onFuncTypeNew) func -> Type {
        FuncType new(token())
    }
    
    /*
     * Operator overloads
     */

    onOperatorStart: unmangled(nq_onOperatorStart) func (symbol: String) {
        oDecl := OperatorDecl new(symbol clone() trim(), token())
        fDecl := FunctionDecl new("", token())
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
        stack push(FunctionDecl new(name clone(), token()))
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
        stack push(FunctionCall new(name clone(), token()))
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
        StringLiteral new(text clone(), token())
    }
    
    onCharLiteral: unmangled(nq_onCharLiteral) func (value: String) -> CharLiteral {
        CharLiteral new(value clone(), token())
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
        ArrayAccess new(array, index, token())
    }
    
    // return
    onReturn: unmangled(nq_onReturn) func (expr: Expression) -> Return {
        Return new(expr, token())
    }
    
    // variable access
    onVarAccess: unmangled(nq_onVarAccess) func (expr: Expression, name: String) -> VariableAccess {
        return VariableAccess new(expr, name clone(), token())
    }
    
    // cast
    onCast: unmangled(nq_onCast) func (expr: Expression, type: Type) -> Cast {
        return Cast new(expr, type, token())
    }
    
    // if
    onIfStart: unmangled(nq_onIfStart) func (condition: Expression) {
        stack push(If new(condition, token()))
    }
    
    onIfEnd: unmangled(nq_onIfEnd) func -> If {
        if1 : If = stack pop()
        //("Wanted to pop an If, got a " + if1 class name) println()
        return if1
    }
    
    // else
    onElseStart: unmangled(nq_onElseStart) func {
        stack push(Else new(token()))
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
        stack push(Foreach new(decl, collec, token()))
    }
    
    onForeachEnd: unmangled(nq_onForeachEnd) func -> Foreach {
        foreach1 : Foreach = stack pop()
        //("Wanted to pop an Foreach, got a " + foreach1 class name) println()
        return foreach1
    }
    
    // while
    onWhileStart: unmangled(nq_onWhileStart) func (condition: Expression) {
        stack push(While new(condition, token()))
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
        peek(List<Node>) add(VarArg new(token()))
    }

    onTypeArg: unmangled(nq_onTypeArg) func (type: Type) {
        // TODO: add check for extern function (TypeArgs are illegal in non-extern functions.)
        peek(List<Node>) add(Argument new(type, "", token()))
    }
    
    onDotArg: unmangled(nq_onDotArg) func (name: String) {
        // TODO: add check for member function
        peek(List<Node>) add(DotArg new(name clone(), token()))
    }
    
    onAssArg: unmangled(nq_onAssArg) func (name: String) {
        // TODO: add check for member function
        peek(List<Node>) add(AssArg new(name clone(), token()))
    }
    
    /*
     * Match & case
     */
    onMatchStart: unmangled(nq_onMatchStart) func {
        stack push(Match new(token()))
    }
    
    onMatchExpr: unmangled(nq_onMatchExpr) func (v:Expression) {
        peek(Match) setExpr(v)
    }
    
    onMatchEnd: unmangled(nq_onMatchEnd) func -> Match {
        pop(Match)
    }

    onCaseStart: unmangled(nq_onCaseStart) func {
        stack push(Case new(token()))
    }
    
    onCaseExpr: unmangled(nq_onCaseExpr) func (v:Expression) {
        peek(Case) setExpr(v)
    }
    
    onCaseEnd: unmangled(nq_onCaseEnd) func {
        pop(Case)
    }
    
    onBreak: unmangled(nq_onBreak) func -> FlowControl {
        FlowControl new(FlowActions _break, token())
    }

    onContinue: unmangled(nq_onContinue) func -> FlowControl {
        FlowControl new(FlowActions _continue, token())
    }

    onEquals: unmangled(nq_onEquals) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes equal, token())
    }
    
    onNotEquals: unmangled(nq_onNotEquals) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes notEqual, token())
    }
    
    onLessThan: unmangled(nq_onLessThan) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes smallerThan, token())
    }
    
    onMoreThan: unmangled(nq_onMoreThan) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes greaterThan, token())
    }
    
    onCmp: unmangled(nq_onCmp) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes compare, token())
    }

    onLessThanOrEqual: unmangled(nq_onLessThanOrEqual) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes smallerOrEqual, token())
    }
    onMoreThanOrEqual: unmangled(nq_onMoreThanOrEqual) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompTypes greaterOrEqual, token())
    }

    onIntLiteral: unmangled(nq_onIntLiteral) func (value: String) -> IntLiteral {
        IntLiteral new(value toLLong(), token())
    }

    onFloatLiteral: unmangled(nq_onFloatLiteral) func (value: String) -> IntLiteral {
        FloatLiteral new(value toFloat(), token())
    }

    onBoolLiteral: unmangled(nq_onBoolLiteral) func (value: Bool) -> BoolLiteral {
        BoolLiteral new(value, token())
    }

    onNull: unmangled(nq_onNull) func -> NullLiteral {
        NullLiteral new(token())
    }

    onTernary: unmangled(nq_onTernary) func (condition, ifTrue, ifFalse: Expression) -> Ternary {
        Ternary new(condition, ifTrue, ifFalse, token())
    }

    onAssignAdd: unmangled(nq_onAssignAdd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes addAss, token())
    }

    onAssignSub: unmangled(nq_onAssignSub) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes subAss, token())
    }

    onAssignMul: unmangled(nq_onAssignMul) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mulAss, token())
    }

    onAssignDiv: unmangled(nq_onAssignDiv) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes divAss, token())
    }

    onAssignAnd: unmangled(nq_onAssignAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bAndAss, token())
    }

    onAssignOr: unmangled(nq_onAssignOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bOrAss, token())
    }

    onAssignXor: unmangled(nq_onAssignXor) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bXorAss, token())
    }

    onAssign: unmangled(nq_onAssign) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes ass, token())
    }
        
    onAssignLeftShift: unmangled(nq_onAssignLeftShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes lshiftAss, token())
    }

    onAssignRightShift: unmangled(nq_onAssignRightShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes rshiftAss, token())
    }

    onAdd: unmangled(nq_onAdd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes add, token())
    }

    onSub: unmangled(nq_onSub) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes sub, token())
    }

    onMod: unmangled(nq_onMod) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mod, token())
    }

    onMul: unmangled(nq_onMul) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes mul, token())
    }

    onDiv: unmangled(nq_onDiv) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes div, token())
    }

    onRangeLiteral: unmangled(nq_onRangeLiteral) func (left, right: Expression) -> RangeLiteral {
        RangeLiteral new(left, right, token())
    }

    onBinaryLeftShift: unmangled(nq_onBinaryLeftShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes lshift, token())
    }

    onBinaryRightShift: unmangled(nq_onBinaryRightShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes rshift, token())
    }

    onLogicalOr: unmangled(nq_onLogicalOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes or, token())
    }

    onLogicalAnd: unmangled(nq_onLogicalAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes and, token())
    }

    onBinaryOr: unmangled(nq_onBinaryOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bOr, token())
    }

    onBinaryXor: unmangled(nq_onBinaryXor) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bXor, token())
    }

    onBinaryAnd: unmangled(nq_onBinaryAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpTypes bAnd, token())
    }

    onLogicalNot: unmangled(nq_onLogicalNot) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes logicalNot, token())
    }

    onBinaryNot: unmangled(nq_onBinaryNot) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes binaryNot, token())
    }

    onUnaryMinus: unmangled(nq_onUnaryMinus) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpTypes unaryMinus, token())
    }

    onParenthesis: unmangled(nq_onParenthesis) func (inner: Expression) -> Parenthesis {
        Parenthesis new(inner, token())
    }
    
    onGenericArgument: unmangled(nq_onGenericArgument) func (name: String) {
        node := peek(Node)
        printf("======= Got generic argument %s, and node is a %s\n", name, node class name)
            
        vDecl := VariableDecl new(BaseType new("Class", token()), name clone(), token())
        if(!node addTypeArgument(vDecl)) {
            token() throwError("Unexpected type argument in a %s declaration!" format(node class name))
        }
        
    }
    
    onAddressOf: unmangled(nq_onAddressOf) func (inner: Expression) -> AddressOf {
        AddressOf new(inner, token())
    }
    
    onDereference: unmangled(nq_onDereference) func (inner: Expression) -> Dereference {
        Dereference new(inner, token())
    }

    token: func -> Token {
        Token new(tokenPos, module)
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
nq_error: unmangled func (this: AstBuilder, errorID: Int, message: String, index: Int) { this error(errorID, message, index) }

