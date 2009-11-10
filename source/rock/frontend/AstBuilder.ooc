import structs/[Array, ArrayList, List, Stack]

import ../frontend/Token
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Line, Include, Type,
    Expression]

nq_parse: extern proto func (String) -> Int

AstBuilder: class {

    modulePath : static String
    module : static Module
    stack : static Stack<Node>

    parse: static func (=modulePath, =module) {
        if(!stack) stack = Stack<Node> new()
        if(!stack isEmpty()) stack clear()
        stack push(module)
        nq_parse(modulePath)
    }
    
    onInclude: static func (path: String) {
        module includes add(Include new(path clone(), IncludeModes PATHY))
    }
    
    onCoverStart: static func (name: String) {
        cDecl := CoverDecl new(name clone(), null, nullToken)
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onCoverFromType: static func (type: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl setFromType(type)
    }
    
    onCoverExtends: static func (superType: Type) {
        cDecl : CoverDecl = stack peek()
        cDecl superType = superType
    }
    
    onCoverEnd: static func {
        node : Node = stack pop()
    }
    
    onClassStart: static func (name: String) {
        cDecl := ClassDecl new(name clone(), null, nullToken)
        module addType(cDecl)
        stack push(cDecl)
    }
    
    onClassExtends: static func (superType: Type) {
        cDecl : ClassDecl = stack peek()
        cDecl superType = superType
    }
    
    onClassAbstract: static func {
        cDecl : ClassDecl = stack peek()
        cDecl isAbstract = true
    }
    
    onClassFinal: static func {
        cDecl : ClassDecl = stack peek()
        cDecl isFinal = true
    }
    
    onClassEnd: static func {
        node : Node = stack pop()
    }
     
    onVarDeclStart: static func {
        stack push(Stack<VariableDecl> new())
    }
    
    onVarDeclName: static func (name: String) {
        vds : Stack<VariableDecl> = stack peek()
        vds push(VariableDecl new(null, name clone(), nullToken))
    }
    
    onVarDeclExpr: static func (expr: Expression) {
        vds : Stack<VariableDecl> = stack peek()
        vds peek() setExpr(expr)
    }
    
    onVarDeclStatic: static func {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            vd setStatic(true)
        }
    }
    
    onVarDeclType: static func (type: Type) {
        vds : Stack<VariableDecl> = stack peek()
        for(vd: VariableDecl in vds) {
            printf("%s is now of type %s\n", vd name, type toString())
            vd type = type
        }
    }
    
    onVarDeclEnd: static func {
        vds : Stack<VariableDecl> = stack pop()
        node : Node = stack peek()
        
        if(node class instanceof(TypeDecl)) {
            
            tDecl := node as TypeDecl
        
            // FIXME do things.. :D
            println("=======================================")
            for(vd: VariableDecl in vds) {
                println(vd toString())
                tDecl addVariable(vd)
            }
            println("=======================================")
            
        }
            
    }
      
    onTypeStart: static func (name: String) -> Type {
        return BaseType new(name clone(), nullToken)
    }
    
    onTypePointer: static func (type: Type) -> Type {
        return PointerType new(type, nullToken)
    }

}

// includes
nq_onInclude: func (path: String)         { AstBuilder onInclude(path) }

// covers
nq_onCoverStart: func (name: String)      { AstBuilder onCoverStart(name) }
nq_onCoverFromType: func (type: Type)     { AstBuilder onCoverFromType(type) }
nq_onCoverExtends: func (superType: Type) { AstBuilder onCoverExtends(superType) }
nq_onCoverEnd: func                       { AstBuilder onCoverEnd() }

// classes
nq_onClassStart: func (name: String)      { AstBuilder onClassStart(name) }
nq_onClassExtends: func (superType: Type) { AstBuilder onClassExtends(superType) }
nq_onClassAbstract: func                  { AstBuilder onClassAbstract() }
nq_onClassFinal: func                     { AstBuilder onClassFinal() }
nq_onClassEnd: func                       { AstBuilder onClassEnd() }

// variable declarations
nq_onVarDeclStart: func                   { AstBuilder onVarDeclStart() }
nq_onVarDeclName: func (name: String)     { AstBuilder onVarDeclName(name) }
nq_onVarDeclExpr: func (expr: Expression) { AstBuilder onVarDeclExpr(expr) }
nq_onVarDeclType: func (type: Type)       { AstBuilder onVarDeclType(type) }
nq_onVarDeclStatic: func                  { AstBuilder onVarDeclStatic() }
nq_onVarDeclEnd: func                     { AstBuilder onVarDeclEnd() }

// types
nq_onTypeNew: func (name: String) -> Type   { return AstBuilder onTypeStart(name) }
nq_onTypePointer: func (type: Type) -> Type { return AstBuilder onTypePointer(type) }


