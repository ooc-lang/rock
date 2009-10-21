import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, Argument, TypeDecl

FunctionDecl: class extends Expression {

    name : String = ""
    suffix : String = ""
    returnType := voidType
    isStatic := false
    
    arguments := ArrayList<Argument> new()
    body := ArrayList<Line> new()
    
    owner : TypeDecl = null

    init: func ~funcDecl (=name, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }
    
    hasReturn: func -> Bool {
        // TODO add Generic support
        //return !getReturnType().isVoid() && !(getReturnType().getRef() instanceof TypeParam);
        returnType != voidType
    }
    
    hasThis: func -> Bool { owner != null }
    
}
