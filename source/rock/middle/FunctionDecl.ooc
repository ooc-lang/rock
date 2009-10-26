import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, Argument, TypeDecl

FunctionDecl: class extends Expression {

    name = "", suffix = null : String
    returnType := voidType
    type: static Type = BaseType new("Func", nullToken)
    
    /** Attributes */
    isAbstract := false
    isStatic := false
    isFinal := false
    externName : String = null
    
    args := ArrayList<Argument> new()
    body := ArrayList<Line> new()
    
    owner : TypeDecl = null

    init: func ~funcDecl (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }
    
    hasReturn: func -> Bool {
        // TODO add Generic support
        //return !getReturnType().isVoid() && !(getReturnType().getRef() instanceof TypeParam);
        returnType != voidType
    }
    
    hasThis:  func -> Bool { isMember() && !isStatic }
    isMember: func -> Bool { owner != null }
    isExtern: func -> Bool { externName != null }
    
    getType: func -> Type { type }
    
}
