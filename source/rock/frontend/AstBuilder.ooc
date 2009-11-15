import structs/[Array, ArrayList, List, Stack, HashMap]

import ../frontend/Token
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Line, Include, Import,
    Type, Expression]

nq_parse: extern proto func (AstBuilder, String) -> Int

AstBuilder: class {

    cache := static HashMap<Module> new()
    modulePath : String
    module : Module
    stack : Stack<Node>

    parse: func (=modulePath, =module) {
        if(!stack) stack = Stack<Node> new()
        if(!stack isEmpty()) stack clear()
        stack push(module)
        nq_parse(this, modulePath)
    }
    
    onInclude: func (path, name: String) {
        inc := Include new(path isEmpty() ? name : path + name, IncludeModes PATHY)
        module includes add(inc)
        printf("Got include %s\n", inc path)
    }
    
    onImport: func  (path, name: String) {
        imp := Import new(path isEmpty() ? name : path + name)
        module includes add(imp)
        printf("Got Import %s\n", imp path)
    }
    
    onCoverStart: func (name: String) {
        cDecl := CoverDecl new(name clone(), null, nullToken)
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
            printf("%s is now of type %s\n", vd name, type toString())
            vd type = type
        }
    }
    
    onVarDeclEnd: func {
        vds : Stack<VariableDecl> = stack pop()
        node : Node = stack peek()
        
        if(node class instanceof(TypeDecl)) {
            
            tDecl := node as TypeDecl
        
            println("=======================================")
            for(vd: VariableDecl in vds) {
                println(vd toString())
                tDecl addVariable(vd)
            }
            println("=======================================")
            
        }
            
    }

    onFuncTypeNew: func -> Type {
        return FuncType new(nullToken)
    }
      
    onTypeNew: func (name: String) -> Type {
        return BaseType new(name clone(), nullToken)
    }
    
    onTypePointer: func (type: Type) -> Type {
        return PointerType new(type, nullToken)
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

