import structs/[Array, ArrayList, List, Stack]

import ../frontend/Token
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl, 
    FunctionCall, StringLiteral, Node, Module, Statement, Line, Include, Type]

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
    
    onCoverEnd: static func {
        node : Node = stack pop()
    }
      
    onTypeStart: static func (name: String) -> Type {
        return BaseType new(name clone(), nullToken)
    }
    
    onTypePointer: static func (type: Type) -> Type {
        return PointerType new(type, nullToken)
    }

}

nq_onInclude: func (path: String) {
    AstBuilder onInclude(path)
}

nq_onCoverStart: func (name: String) {
    AstBuilder onCoverStart(name)
}

nq_onCoverFromType: func (type: Type) {
    AstBuilder onCoverFromType(type)
}

nq_onCoverEnd: func {
    AstBuilder onCoverEnd()
}

nq_onTypeStart: func (name: String) -> Type {
    return AstBuilder onTypeStart(name)
}

nq_onTypePointer: func (type: Type) -> Type {
    return AstBuilder onTypePointer(type)
}


