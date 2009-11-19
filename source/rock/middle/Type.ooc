import ../frontend/Token
import ../backend/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, Module, Import
import tinker/[Response, Resolver, Trail]

voidType := BaseType new("void", nullToken)
voidType ref = BuiltinType new("void", nullToken)

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
    setRef: abstract func (d: Declaration)
    
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
    setRef: func (d: Declaration) {}
    
}

BaseType: class extends Type {

    ref: TypeDecl = null
    name: String
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    
    write: func (w: AwesomeWriter) {
        if(ref == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        w app(ref underName())
        if(ref instanceOf(ClassDecl))
            w app("*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as BaseType name equals(name))
    }
    
    getName: func -> String { name }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        if(isResolved()) return Responses OK
    
        //printf("resolving type %s (ref = %p)\n", name, ref)
        
        module := trail module()
        
        this ref = module types get(name)
        if(ref == null) {
            for(imp in module imports) {
                //printf("Looking in import %s\n", imp path)
                this ref = imp getModule() types get(name)
                if(ref != null) {
                    //("Found type " + name + " in " + imp getModule() fullName)
                    break
                }
            }
        }
        
        if(ref == null) {
            return Responses LOOP
        //} else {
            //("Found match! " + name) println()
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool { ref != null }
    
    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}

}

SugarType: abstract class extends Type {
    
    inner: Type
    
    init: func ~sugarType (=inner, .token) { super(token) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    getRef: func -> Declaration { inner getRef() }
    setRef: func (d: Declaration) { inner setRef(d) }
    
}

PointerType: class extends SugarType {
    
    init: func ~pointerType (.inner, .token) { super(inner, token) }
    
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

ReferenceType: class extends SugarType {
    
    init: func ~pointerType (.inner, .token) { super(inner, token) }
    
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
