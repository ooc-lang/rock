import structs/[ArrayList, List]
import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, VariableDecl,
       Module, Import, CoverDecl
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
    
    toMangledString: func -> String { getName() }
    
    // FIXME: stub
    getGroundType: func -> Type { this }
    
    getRef: abstract func -> Declaration
    setRef: abstract func (d: Declaration)
    
    isGeneric: func -> Bool {
        if(getRef()) {
            //printf("ref of %s is %s %s\n", toString(), getRef() class name, getRef() toString())
            return getRef() instanceOf(VariableDecl)
        }
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    clone: abstract func -> This
    
    reference:   func          -> This { PointerType new(this, token) }
    dereference: abstract func -> This
    
    getTypeArgs: abstract func -> List<VariableDecl>
    
    getScore: func (other: This) -> Int {
        scoreSeed := 4096
        current := this
        while(current != null) {
            score := getScoreImpl(other, scoreSeed)
            if(score > 0) {
                return score
            }
            current = current dig()
            scoreSeed -= 1
        }
    }
    
    getScoreImpl: abstract func (other: This, scoreSeed: Int) -> Int
    
    dig: abstract func -> This
    
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
    
    // should we throw an error or something?
    dereference : func -> This { null }
    
    // TODO: clone arguments, when the FuncType is fleshed out
    clone: func -> This { new(token) }
    
    getTypeArgs: func -> List<VariableDecl> { null }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf(FuncType)) {
            return scoreSeed
        }
        return 0
    }
    
    dig: func -> Type { null }
    
}

BaseType: class extends Type {

    ref: Declaration = null
    name: String
    
    typeArgs := ArrayList<VariableDecl> new()
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    
    write: func (w: AwesomeWriter) {
        if(ref == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        match {
            case ref instanceOf(TypeDecl)     => writeRegularType(w, ref)
            case ref instanceOf(VariableDecl) => writeGenericType(w, ref)
        }
    }
    
    writeRegularType: func (w: AwesomeWriter, td: TypeDecl) {
        w app(td underName())
        if(td instanceOf(ClassDecl)) {
            w app("*")
        }
    }
    
    writeGenericType: func (w: AwesomeWriter, vd: VariableDecl) {
        w app("uint8_t*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as BaseType name equals(name))
    }
    
    addTypeArgument: func (typeArg: VariableDecl) -> Bool { typeArgs add(typeArg); true }
    
    getName: func -> String { name }
    
    suggest: func (decl: Declaration) -> Bool {
        // trivial impl for now
        ref = decl
        return true
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        if(isResolved()) return Responses OK
        
        if(!ref) {
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth)
                node resolveType(this)
                if(ref) break // break on first match
                depth -= 1
            }
        }
        
        if(ref == null) {
            if(res fatal) {
                token throwError("Can't resolve type %s!" format(toString()))
            }
            if(res params verbose) {
                printf("     - type %s still not resolved, looping (ref = %p)\n", name, ref)
            }
            return Responses LOOP
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool { ref != null }
    
    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}
    
    getTypeArgs: func -> List<VariableDecl> { typeArgs }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf(BaseType)) {
            return (other getName() equals(getName()) ? scoreSeed : 0)
        }
        return 0
    }
    
    // should we throw an error or something?
    dereference : func -> This { null }
    
    clone: func -> This { new(name, token) }
    
    dig: func -> Type {
        if(ref != null && ref instanceOf(CoverDecl)) {
            return ref as CoverDecl getFromType()
        }
        return null
    }

}

SugarType: abstract class extends Type {
    
    inner: Type
    
    init: func ~sugarType (=inner, .token) { super(token) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    getRef: func -> Declaration   { inner getRef()  }
    setRef: func (d: Declaration) { inner setRef(d) }
    
    getTypeArgs: func -> List<VariableDecl> { inner getTypeArgs() }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        return (other instanceOf(class) ? inner getScore(other as SugarType inner) : 0)
    }
    
    getName: func -> String { inner getName() }
    
    dig: func -> Type {
        innerUnder := inner dig()
        if(innerUnder) {
            under := clone() as SugarType
            under inner = innerUnder
            return under
        }
        return null
    }
    
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
    
    toString: func -> String { inner toString() + "*" }
    toMangledString: func -> String { inner toString() + "__star" }
    
    dereference : func -> This { inner }
    
    clone: func -> This { new(inner, token) }
    
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
    
    toString: func -> String { inner toString() + "@" }
    toMangledString: func -> String { inner toString() + "__star" }
    
    dereference : func -> This { inner }
    
    clone: func -> This { new(inner, token) }
    
}
