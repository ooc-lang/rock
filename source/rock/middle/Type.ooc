import ../frontend/Token
import ../backend/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, Module
import tinker/[Response, Resolver, Trail]

voidType := BaseType new("void", nullToken)

Type: abstract class extends Node {
    
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
    
    getRef: abstract func -> Declaration
    
}

FuncType: class extends Type {
    
    init: func ~funcType (.token) { super(token) }
    
    write: func (w: AwesomeWriter) {
        w app ("Func")
    }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        // FIXME compare types
        return true
    }
    
    getName: func -> String { "Func" }
    
    getRef: func -> Declaration { null }
    
}

BaseType: class extends Type {

    ref: TypeDecl = null
    name: String
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    
    write: func (w: AwesomeWriter) {
        if(ref == null) {
            Exception new(This, "Trying to write unresolved type " + toString())
        }
        w app(ref underName())
        if(ref class instanceof(ClassDecl))
            w app("*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as BaseType name equals(name))
    }
    
    getName: func -> String { name }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        printf("resolving type %s (ref = %p)\n", name, ref)
        
        module := trail module()
        for(tDecl: TypeDecl in module types) {
            if(tDecl name == this name) {
                ("Found match! " + name) println()
                ref = tDecl
            }
        }
        
        if(ref == null) {
            return Responses LOOP
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool { ref != null }
    
    getRef: func -> Declaration { ref }

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
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    
    getRef: func -> Declaration { inner getRef() }
    
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
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    
    getRef: func -> Declaration { inner getRef() }
    
}
