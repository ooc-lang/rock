import io/File

import structs/[Array, ArrayList, List, Stack, HashMap]

import ../frontend/[Token, BuildParams]
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Include, Import,
    Type, Expression, Return, VariableAccess, Cast, If, Else, ControlStatement,
    Comparison, IntLiteral, Ternary, BinaryOp, BoolLiteral, Argument, Parenthesis,
    AddressOf, Dereference, Foreach]

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
        //printCache()
        
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
    
    onInclude: func (path, name: String) {
        inc := Include new(path isEmpty() ? name : path + name, IncludeModes PATHY)
        module includes add(inc)
        //printf("Got include %s\n", inc path)
    }
    
    onImport: func  (path, name: String) {
        imp := Import new(path isEmpty() ? name : path + name)
        module imports add(imp)
        //printf("Got Import %s\n", imp path)
    }
    
    onCoverStart: func (name: String) {
        cDecl := CoverDecl new(name clone(), null, Token new(this tokenPos, this module))
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onCoverFromType: func (type: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl setFromType(type)
    }
    
    onCoverExtends: func (superType: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl superType = superType
    }
    
    onCoverEnd: func {
        node : Node = stack pop()
    }
    
    onClassStart: func (name: String) {
        cDecl := ClassDecl new(name clone(), null, Token new(this tokenPos, this module))
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onClassExtends: func (superType: Type) {
        cDecl : ClassDecl = stack peek()
        cDecl superType = superType
    }
    
    onClassAbstract: func {
        cDecl : ClassDecl = stack peek()
        cDecl isAbstract = true
    }
    
    onClassFinal: func {
        cDecl : ClassDecl = stack peek()
        cDecl isFinal = true
    }
    
    onClassEnd: func {
        node : Node = stack pop()
    }
     
    onVarDeclStart: func {
        stack push(Stack<VariableDecl> new())
    }
    
    onVarDeclName: func (name: String) {
        vds : Stack<VariableDecl> = stack peek()
        vds push(VariableDecl new(null, name clone(), Token new(this tokenPos, this module)))
    }
    
    onVarDeclExpr: func (expr: Expression) {
        vds : Stack<VariableDecl> = stack peek()
        vds peek() setExpr(expr)
    }
    
    onVarDeclStatic: func {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            vd setStatic(true)
        }
    }
    
    onVarDeclType: func (type: Type) {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            vd type = type
        }
    }
    
    onVarDeclEnd: func -> Stack<VariableDecl> {
        vds : Stack<VariableDecl> = stack pop()
        return vds
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

    onFuncTypeNew: func -> Type {
        return FuncType new(Token new(this tokenPos, this module))
    }
      
    onTypeNew: func (name: String) -> Type {
        return BaseType new(name clone() trim(), Token new(this tokenPos, this module))
    }
    
    onTypePointer: func (type: Type) -> Type {
        return PointerType new(type, Token new(this tokenPos, this module))
    }
    
    onFunctionStart: func (name: String) {
        fDecl := FunctionDecl new(name clone(), Token new(this tokenPos, this module))
        stack push(fDecl)
    }
    
    onFunctionExtern: func (externName: String) {
        fDecl : FunctionDecl = stack peek()
        fDecl externName = externName clone()
    }
    
    onFunctionAbstract: func {
        fDecl : FunctionDecl = stack peek()
        fDecl isAbstract = true
    }
    onFunctionStatic: func {
        fDecl : FunctionDecl = stack peek()
        fDecl isStatic = true
    }
    onFunctionInline: func {
        fDecl : FunctionDecl = stack peek()
        fDecl isInline = true
    }
    
    onFunctionFinal: func {
        fDecl : FunctionDecl = stack peek()
        fDecl isFinal = true
    }
    
    onFunctionSuffix: func (suffix: String) {
        fDecl : FunctionDecl = stack peek()
        fDecl suffix = suffix clone()
    }
    
    onFunctionArgsStart: func {
        fDecl : FunctionDecl = stack peek()
        stack push(fDecl args)
    }
    
    onFunctionArgsEnd: func {
        node : Node = stack pop()
        //printf("Wanted to pop an ArrayList, got a %s\n", node class name)
    }
    
    onFunctionReturnType: func (type: Type) {
        fDecl : FunctionDecl = stack peek()
        fDecl returnType = type
    }
    
    onFunctionEnd: func -> FunctionDecl {
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
    
    // function calls
    onFunctionCallStart: func (name: String) {
        fCall := FunctionCall new(name clone(), Token new(this tokenPos, this module))
        stack push(fCall)
    }
    
    onFunctionCallArg: func (expr: Expression) {
        fCall : FunctionCall = stack peek()
        fCall args add(expr)
        //printf("Function call to %s got arg %p\n", fCall name, expr)
    }
    
    onFunctionCallEnd: func -> FunctionCall {
        node : Node = stack pop()
        //printf("Wanted to pop a FunctionCall, got a %s\n", node class name)
        return node as FunctionCall
    }
    
    onFunctionCallExpr: func (call: FunctionCall, expr: Expression) {
        //printf("Call to %s became a member call of expression %s\n", call toString(), expr toString())
        call expr = expr
    }
    
    // literals
    onStringLiteral: func (text: String) -> StringLiteral {
        sl := StringLiteral new(text clone(), Token new(this tokenPos, this module))
        //printf("Got string literal %s\n", sl toString())
        return sl
    }
    
    // statement
    onStatement: func (stmt: Statement) {
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
    
    // return
    onReturn: func (expr: Expression) -> Return {
        ret := Return new(expr, Token new(this tokenPos, this module))
        //printf("Got return %p with expr %s (%p)\n", ret, expr ? expr toString() : "(nil)", expr)
        return ret
    }
    
    // variable access
    onVarAccess: func (expr: Expression, name: String) -> VariableAccess {
        return VariableAccess new(expr, name clone(), Token new(this tokenPos, this module))
    }
    
    // cast
    onCast: func (expr: Expression, type: Type) -> Cast {
        return Cast new(expr, type, Token new(this tokenPos, this module))
    }
    
    // if
    onIfStart: func (condition: Expression) {
        stack push(If new(condition, Token new(this tokenPos, this module)))
    }
    
    onIfEnd: func -> If {
        if1 : If = stack pop()
        //("Wanted to pop an If, got a " + if1 class name) println()
        return if1
    }
    
    // else
    onElseStart: func {
        stack push(Else new(Token new(this tokenPos, this module)))
    }
    
    onElseEnd: func -> If {
        else1 : Else = stack pop()
        //("Wanted to pop an Else, got a " + else1 class name) println()
        return else1
    }
    
    // foreach
    onForeachStart: func (decl, collec: Expression) {
        stack push(Foreach new(decl, collec, Token new(this tokenPos, this module)))
    }
    
    onForeachEnd: func -> If {
        foreach1 : Foreach = stack pop()
        //("Wanted to pop an Foreach, got a " + foreach1 class name) println()
        return foreach1
    }

}

// position in stream handling
nq_setTokenPositionPointer: func (this: AstBuilder, tokenPos: Int*) { this tokenPos = tokenPos }

// string handling
nq_StringClone: func (string: String) -> String             { string clone() }

// includes, imports
nq_onInclude: func (this: AstBuilder, path, name: String)   { this onInclude(path, name) }
nq_onImport:  func (this: AstBuilder, path, name: String)   { this onImport(path, name) }

// covers
nq_onCoverStart: func (this: AstBuilder, name: String)      { this onCoverStart(name) }
nq_onCoverFromType: func (this: AstBuilder, type: Type)     { this onCoverFromType(type) }
nq_onCoverExtends: func (this: AstBuilder, superType: Type) { this onCoverExtends(superType) }
nq_onCoverEnd: func (this: AstBuilder)                      { this onCoverEnd() }

// classes
nq_onClassStart: func (this: AstBuilder, name: String)      { this onClassStart(name) }
nq_onClassExtends: func (this: AstBuilder, superType: Type) { this onClassExtends(superType) }
nq_onClassAbstract: func (this: AstBuilder)                 { this onClassAbstract() }
nq_onClassFinal: func (this: AstBuilder)                    { this onClassFinal() }
nq_onClassEnd: func (this: AstBuilder)                      { this onClassEnd() }

// variable declarations
nq_onVarDeclStart: func (this: AstBuilder)                      { this onVarDeclStart() }
nq_onVarDeclName: func (this: AstBuilder, name: String)         { this onVarDeclName(name) }
nq_onVarDeclExpr: func (this: AstBuilder, expr: Expression)     { this onVarDeclExpr(expr) }
nq_onVarDeclType: func (this: AstBuilder, type: Type)           { this onVarDeclType(type) }
nq_onVarDeclStatic: func (this: AstBuilder)                     { this onVarDeclStatic() }
nq_onVarDeclEnd: func (this: AstBuilder) -> Stack<VariableDecl> { this onVarDeclEnd() }

nq_onVarDeclAssign: func (this: AstBuilder, acc: VariableAccess, isConst: Bool, expr: Expression) -> VariableDecl {
    if(!acc instanceOf(VariableAccess)) {
        Exception new(AstBuilder, "Expected a VariableAccess as a left-hand-side of a decl-assign, but got a " + acc toString()) throw()
    }
    vDecl := VariableDecl new(null, acc name, expr, Token new(this tokenPos, this module))
    vDecl isConst = isConst
    //if(isConst) "%s is const!" format(acc name) println()
    //("Got variableDecl " + vDecl toString()) println()
    return vDecl
}

// types
nq_onTypeNew: func (this: AstBuilder, name: String) -> Type   { return this onTypeNew(name) }
nq_onTypePointer: func (this: AstBuilder, type: Type) -> Type { return this onTypePointer(type) }
nq_onFuncTypeNew: func (this: AstBuilder) -> Type             { return this onFuncTypeNew() }

// functions
nq_onFunctionStart: func (this: AstBuilder, name: String)       { this onFunctionStart(name) }
nq_onFunctionExtern: func (this: AstBuilder, externName: String){ this onFunctionExtern(externName) }
nq_onFunctionAbstract: func (this: AstBuilder)                  { this onFunctionAbstract() }
nq_onFunctionStatic: func (this: AstBuilder)                    { this onFunctionStatic() }
nq_onFunctionInline: func (this: AstBuilder)                    { this onFunctionInline() }
nq_onFunctionFinal: func (this: AstBuilder)                     { this onFunctionFinal() }
nq_onFunctionSuffix: func (this: AstBuilder, suffix: String)    { this onFunctionSuffix(suffix) }
nq_onFunctionArgsStart: func (this: AstBuilder)                 { this onFunctionArgsStart() }
nq_onFunctionArgsEnd: func (this: AstBuilder)                   { this onFunctionArgsEnd() }
nq_onFunctionReturnType: func (this: AstBuilder, type: Type)    { this onFunctionReturnType(type) }
nq_onFunctionEnd: func (this: AstBuilder) -> FunctionDecl       { return this onFunctionEnd() }

// function calls
nq_onFunctionCallStart: func (this: AstBuilder, name: String)     { this onFunctionCallStart(name) }
nq_onFunctionCallArg: func (this: AstBuilder, arg: Expression)    { this onFunctionCallArg(arg) }
nq_onFunctionCallEnd: func (this: AstBuilder) -> FunctionCall     { return this onFunctionCallEnd() }
nq_onFunctionCallExpr: func (this: AstBuilder, call: FunctionCall, expr: Expression)  { this onFunctionCallExpr(call, expr) }

// literals
nq_onStringLiteral: func (this: AstBuilder, text: String) -> StringLiteral   { return this onStringLiteral(text) }

// statement
nq_onStatement: func (this: AstBuilder, stmt: Statement)                 { this onStatement(stmt) }
nq_onReturn: func (this: AstBuilder, expr: Expression) -> Return         { return this onReturn(expr) }
nq_onVarAccess: func (this: AstBuilder, expr: Expression, name: String) -> VariableAccess  { return this onVarAccess(expr, name) }
nq_onCast: func (this: AstBuilder, expr: Expression, type: Type) -> Cast { return this onCast(expr, type) }

nq_onIfStart: func (this: AstBuilder, condition: Expression)             { this onIfStart(condition) }
nq_onIfEnd: func (this: AstBuilder) -> If                                { return this onIfEnd() }
nq_onElseStart: func (this: AstBuilder)                                  { this onElseStart() }
nq_onElseEnd: func (this: AstBuilder) -> Else                            { return this onElseEnd() }

nq_onForeachStart: func (this: AstBuilder, decl, collec: Expression)     { this onForeachStart(decl, collec) }
nq_onForeachEnd: func (this: AstBuilder) -> Foreach                      { return this onForeachEnd() }

nq_onEquals: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes equal, Token new(this tokenPos, this module))
}
nq_onNotEquals: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes notEqual, Token new(this tokenPos, this module))
}
nq_onLessThan: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes smallerThan, Token new(this tokenPos, this module))
}
nq_onMoreThan: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes greaterThan, Token new(this tokenPos, this module))
}
nq_onLessThanOrEqual: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes smallerOrEqual, Token new(this tokenPos, this module))
}
nq_onMoreThanOrEqual: func (this: AstBuilder, left, right: Expression) -> Comparison {
    return Comparison new(left, right, CompTypes greaterOrEqual, Token new(this tokenPos, this module))
}

nq_onIntLiteral: func (this: AstBuilder, value: String) -> IntLiteral {
    return IntLiteral new(value toLLong(), Token new(this tokenPos, this module))
}

nq_onBoolLiteral: func (this: AstBuilder, value: Bool) -> BoolLiteral {
    return BoolLiteral new(value, Token new(this tokenPos, this module))
}

nq_onTernary: func (this: AstBuilder, condition, ifTrue, ifFalse: Expression) -> Ternary {
    return Ternary new(condition, ifTrue, ifFalse, Token new(this tokenPos, this module))
}

nq_onAssignAdd: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes addAss, Token new(this tokenPos, this module))
}

nq_onAssignSub: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes subAss, Token new(this tokenPos, this module))
}

nq_onAssignMul: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mulAss, Token new(this tokenPos, this module))
}

nq_onAssignDiv: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes divAss, Token new(this tokenPos, this module))
}

nq_onAssignAnd: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bAndAss, Token new(this tokenPos, this module))
}

nq_onAssignOr: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bOrAss, Token new(this tokenPos, this module))
}

nq_onAssignXor: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes bXorAss, Token new(this tokenPos, this module))
}

nq_onAssign: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes ass, Token new(this tokenPos, this module))
}
    
nq_onAssignLeftShift: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes lshiftAss, Token new(this tokenPos, this module))
}

nq_onAssignRightShift: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes rshiftAss, Token new(this tokenPos, this module))
}

nq_onAdd: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes add, Token new(this tokenPos, this module))
}

nq_onSub: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes sub, Token new(this tokenPos, this module))
}

nq_onMod: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mod, Token new(this tokenPos, this module))
}

nq_onMul: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes mul, Token new(this tokenPos, this module))
}

nq_onDiv: func (this: AstBuilder, left, right: Expression) -> BinaryOp {
    return BinaryOp new(left, right, OpTypes div, Token new(this tokenPos, this module))
}

nq_onVarArg: func (this: AstBuilder) -> VarArg {
    return VarArg new(Token new(this tokenPos, this module))
}

nq_onParenthesis: func (this: AstBuilder, inner: Expression) -> Parenthesis {
    return Parenthesis new(inner, Token new(this tokenPos, this module))
}

nq_onGenericArgument: func (this: AstBuilder, name: String) {
    
    node : Node = this stack peek()
    printf("======= Got generic argument %s, and node is a %s\n", name, node class name)
    
    match {
        case node instanceOf(FunctionDecl) =>
            fDecl := node as FunctionDecl
            fDecl typeArgs add(VariableDecl new(BaseType new("Class", Token new(this tokenPos, this module)), name clone(), Token new(this tokenPos, this module)))
    }
}

nq_onAddressOf:   func (this: AstBuilder, inner: Expression) -> AddressOf   { return AddressOf   new(inner, Token new(this tokenPos, this module)) }
nq_onDereference: func (this: AstBuilder, inner: Expression) -> Dereference { return Dereference new(inner, Token new(this tokenPos, this module)) }

nq_error: func (this: AstBuilder, errorID: Int, message: String, index: Int) { this error(errorID, message, index) }

