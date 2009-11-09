import ../frontend/Token
import ../backend/AwesomeWriter
import Node, Visitor, Declaration

voidType := BaseType new("void", nullToken)

Type: abstract class extends Node {
    
    ref: Declaration = null
    
    init: func ~type (.token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitType(this) }
    
    pointerLevel: abstract func -> Int
    refLevel:     abstract func -> Int
    
    write: abstract func (w: AwesomeWriter)
    
    equals: abstract func (other: This) -> Bool
    
    getName: abstract func -> String
    
    toString: func -> String { getName() }
    
    // FIXME: stub
    getGroundType: func -> Type { this }
    
}

BaseType: class extends Type {

    name: String
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    
    write: func (w: AwesomeWriter) {
        w app(name)
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as BaseType name equals(name))
    }
    
    getName: func -> String { name }

}

PointerType: class extends Type {
    
    inner: Type
    
    init: func ~pointerType (=inner, .token) { super(token) }
    
    pointerLevel: func -> Int { inner pointerLevel() + 1 }
    refLevel:     func -> Int { inner refLevel() }
    
    write: func (w: AwesomeWriter) {
        inner write(w)
        w app("*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as PointerType inner equals(inner))
    }
    
    getName: func -> String { inner getName() + "*" }
    
}

ReferenceType: class extends Type {
    
    inner: Type
    
    init: func ~referenceType (=inner, .token) { super(token) }
    
    pointerLevel: func -> Int { inner pointerLevel() }
    refLevel:     func -> Int { inner refLevel() + 1 }
    
    write: func (w: AwesomeWriter) {
        inner write(w)
        w app("*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as PointerType inner equals(inner))
    }
    
    getName: func -> String { inner getName() + "@" }
    
}


