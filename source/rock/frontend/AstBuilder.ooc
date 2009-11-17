import io/File

import structs/[Array, ArrayList, List, Stack, HashMap]

import ../frontend/[Token, BuildParams]
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Line, Include, Import,
    Type, Expression, Return]

nq_parse: extern proto func (AstBuilder, String) -> Int

AstBuilder: class {

    cache := static HashMap<Module> new()
    
    params : BuildParams
    modulePath : String
    module : Module
    stack : Stack<Node>

    init: func (=modulePath, =module, =params) {
        
        if(params verbose) {
            printf("Parsing %s (for module %s)\n", modulePath, module fullName)
        }
        cache put(modulePath, module)
        printCache()
        
        stack = Stack<Node> new()
        stack push(module)
        result := nq_parse(this, modulePath)
        if(result == -1) {
            Exception new(This, "File " +modulePath + " not found") throw()
        }
        
        addLangImports()
        parseImports()
        
    }
    
    addLangImports: func {
    
        paths := params sourcePath getRelativePaths("lang")
        for(path in paths) {
            if(path endsWith(".ooc")) {
                impName := path substring(0, path length() - 4)
                if(impName != module fullName) {
                    printf("Adding import %s to %s\n", impName, module fullName)
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
            
            println("Trying to get "+path+" from cache")
            cached : Module = null
            cached = cache get(path)
            
            //if(!cached || File new(impPath path) lastModified() > cached lastModified) {
            if(!cached) {
                if(cached) {
                    println(path+" has been changed, recompiling...");
                }
                cached = Module new(path substring(0, path length() - 4), impElement path, nullToken)
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
    
    onInclude: func (path, name: String) {
        inc := Include new(path isEmpty() ? name : path + name, IncludeModes PATHY)
        module includes add(inc)
        printf("Got include %s\n", inc path)
    }
    
    onImport: func  (path, name: String) {
        imp := Import new(path isEmpty() ? name : path + name)
        module imports add(imp)
        printf("Got Import %s\n", imp path)
    }
    
    onCoverStart: func (name: String) {
        cDecl := CoverDecl new(name clone(), null, nullToken)
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
        cDecl := ClassDecl new(name clone(), null, nullToken)
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
        vds push(VariableDecl new(null, name clone(), nullToken))
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
    
    onVarDeclEnd: func {
        vds : Stack<VariableDecl> = stack pop()
        node : Node = stack peek()
        
        if(node class instanceof(TypeDecl)) {
            tDecl := node as TypeDecl
            for(vd: VariableDecl in vds) {
                tDecl addVariable(vd)
            }
        } else {
            printf("^^^^^^^ Unexpected varDecl " + vds peek() toString())
        }
            
    }

    onFuncTypeNew: func -> Type {
        return FuncType new(nullToken)
    }
      
    onTypeNew: func (name: String) -> Type {
        return BaseType new(name clone() trim(), nullToken)
    }
    
    onTypePointer: func (type: Type) -> Type {
        return PointerType new(type, nullToken)
    }
    
    onFunctionStart: func (name: String) {
        fDecl := FunctionDecl new(name clone(), nullToken)
        stack push(fDecl)
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
        printf("Wanted to pop an ArrayList, got a %s\n", node class name)
    }
    
    onFunctionReturnType: func (type: Type) {
        fDecl : FunctionDecl = stack peek()
        fDecl returnType = type
        printf("returnType of %s is now %s\n", fDecl toString(), type toString())
    }
    
    onFunctionEnd: func -> FunctionDecl {
        fDecl : FunctionDecl = stack pop()
        node : Node = stack peek()
        if(node == module) {
            module addFunction(fDecl)
        } else {
            printf("Unexpected function %s\n", fDecl name)
        }
        return fDecl
    }
    
    // function calls
    onFunctionCallStart: func (name: String) {
        fCall := FunctionCall new(name clone(), nullToken)
        stack push(fCall)
    }
    
    onFunctionCallArg: func (expr: Expression) {
        fCall : FunctionCall = stack peek()
        fCall args add(expr)
        printf("Function call to %s got arg %p\n", fCall name, expr)
    }
    
    onFunctionCallEnd: func -> FunctionCall {
        node : Node = stack pop()
        printf("Wanted to pop a FunctionCall, got a %s\n", node class name)
        return node as FunctionCall
    }
    
    // literals
    onStringLiteral: func (text: String) -> StringLiteral {
        sl := StringLiteral new(text clone(), nullToken)
        printf("Got string literal %s\n", sl toString())
        return sl
    }
    
    // statement
    onStatement: func (stmt: Statement) {
        node : Node = stack peek()
        printf("Got a statement which is a %s, and peek is a %s\n", stmt class name, node class name)
        match node class {
            case FunctionDecl =>
                fDecl : FunctionDecl = node
                fDecl body add(Line new(stmt))
                printf("Added line to function decl %s\n", fDecl name)
        }
    }
    
    // return
    onReturn: func (expr: Expression) -> Return {
        ret := Return new(expr, nullToken)
        printf("Got return %p\n", expr)
        return ret
    }

}

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
nq_onVarDeclStart: func (this: AstBuilder)                  { this onVarDeclStart() }
nq_onVarDeclName: func (this: AstBuilder, name: String)     { this onVarDeclName(name) }
nq_onVarDeclExpr: func (this: AstBuilder, expr: Expression) { this onVarDeclExpr(expr) }
nq_onVarDeclType: func (this: AstBuilder, type: Type)       { this onVarDeclType(type) }
nq_onVarDeclStatic: func (this: AstBuilder)                 { this onVarDeclStatic() }
nq_onVarDeclEnd: func (this: AstBuilder)                    { this onVarDeclEnd() }

// types
nq_onTypeNew: func (this: AstBuilder, name: String) -> Type   { return this onTypeNew(name) }
nq_onTypePointer: func (this: AstBuilder, type: Type) -> Type { return this onTypePointer(type) }
nq_onFuncTypeNew: func (this: AstBuilder) -> Type             { return this onFuncTypeNew() }

// functions
nq_onFunctionStart: func (this: AstBuilder, name: String)       { this onFunctionStart(name) }
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
nq_onFunctionCallStart: func (this: AstBuilder, name: String)   { this onFunctionCallStart(name) }
nq_onFunctionCallArg: func (this: AstBuilder, arg: Expression)  { this onFunctionCallArg(arg) }
nq_onFunctionCallEnd: func (this: AstBuilder) -> FunctionCall   { return this onFunctionCallEnd() }

// literals
nq_onStringLiteral: func (this: AstBuilder, text: String) -> StringLiteral   { return this onStringLiteral(text) }

// statement
nq_onStatement: func (this: AstBuilder, stmt: Statement)         { this onStatement(stmt) }
nq_onReturn: func (this: AstBuilder, expr: Expression) -> Return { return this onReturn(expr) }

