import text/Buffer
import structs/[ArrayList, List]
import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, VariableDecl,
       Module, Import, CoverDecl, VariableAccess, Expression, InterfaceDecl
import tinker/[Response, Resolver, Trail]

voidType := BaseType new("void", nullToken)
voidType ref = BuiltinType new("void", nullToken)

Type: abstract class extends Expression {
    
    NOLUCK_SCORE := const -100000
    
    init: func ~type (.token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitType(this) }
    
    pointerLevel: abstract func -> Int
    refLevel:     abstract func -> Int
    
    write: abstract func (w: AwesomeWriter, name: String)
    
    equals: abstract func (other: This) -> Bool
    
    getName: abstract func -> String
    
    toString: func -> String { getName() }
    
    toMangledString: func -> String { getName() }
    
    getGroundType: func -> Type {
        under := this
        while (under != null) {
            candidate := under dig()
            if(candidate) {
                under = candidate
            } else {
                break
            }
        }
        return under
    }
    
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
    
    reference:   func          -> This { p := PointerType new(this, token); p setRef(getRef()); p }
    dereference: abstract func -> This
    
    getTypeArgs: abstract func -> List<VariableAccess>
    
    getType: func -> This {
        getRef() ? getRef() getType() : null
    }
    
    getScore: func (other: This) -> Int {
        bestScore := NOLUCK_SCORE
        scoreSeed := 1024
        current := this
        while(current != null) {
            score := getScoreImpl(other, scoreSeed)
            if(score > bestScore) {
                bestScore = score
            }
            current = current dig()
            scoreSeed -= 1
        }
        return bestScore
    }
    
    isPointer: func -> Bool { pointerLevel() > 0 }
    
    getScoreImpl: abstract func (other: This, scoreSeed: Int) -> Int
    
    inheritsFrom: func (t: This) -> Bool { false }
    
    dig: abstract func -> This
    
}

FuncType: class extends Type {
    
    init: func ~funcType (.token) { super(token) }
    
    write: func (w: AwesomeWriter, name: String) {
        w app ("Func")
        if(name != null) w app(' '). app(name)
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
    
    getTypeArgs: func -> List<VariableAccess> { null }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf(FuncType)) {
            return scoreSeed
        }
        return NOLUCK_SCORE
    }
    
    isPointer: func -> Bool { true }
    
    dig: func -> Type { null }
    
}

BaseType: class extends Type {

    ref: Declaration = null
    name: String
    
    typeArgs: List<VariableAccess>
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    refLevel:     func -> Int { 0 }
    
    isPointer: func -> Bool { name == "Pointer" }
    
    write: func (w: AwesomeWriter, name: String) {
        if(ref == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        match {
            case ref instanceOf(InterfaceDecl)=> writeInterfaceType(w, ref)
            case ref instanceOf(TypeDecl)     => writeRegularType(w, ref)
            case ref instanceOf(VariableDecl) => writeGenericType(w, ref)
        }
        if(name != null) w app(' '). app(name)
    }
    
    writeInterfaceType: func (w: AwesomeWriter, id: InterfaceDecl) {
        w app(id getFatType() getInstanceType())
    }
    
    writeRegularType: func (w: AwesomeWriter, td: TypeDecl) {
        if(td isExtern()) {
            w app(td getExternName())
            return
        }
        
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
    
    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        if(!typeArgs) typeArgs = ArrayList<VariableAccess> new()
        typeArgs add(typeArg); true
    }
    
    getName: func -> String { name }
    
    suggest: func (decl: Declaration) -> Bool {
        ref = decl
        if(name == "This" && ref instanceOf(TypeDecl)) {
            // not exactly sure how good an idea it is
            tDecl := ref as TypeDecl
            name = tDecl getName()
        }
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
                token throwError("Can't resolve type %s!" format(getName()))
            }
            if(res params verbose) {
                printf("     - type %s still not resolved, looping (ref = %p)\n", name, ref)
            }
            return Responses LOOP
        }
        
        if(typeArgs) for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool {
        if(ref == null) return false
        if(typeArgs == null) return true
        for(typeArg in typeArgs) if(!typeArg isResolved()) {
            return false
        }
        return true
    }
    
    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}
    
    getTypeArgs: func -> List<VariableDecl> { typeArgs }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf(BaseType)) {
            return (other getName() equals(getName()) ? scoreSeed : NOLUCK_SCORE)
        }
        return NOLUCK_SCORE // no luck.
    }
    
    dereference: func -> This {
        digged := dig()
        if(digged) {
            return digged dereference()
        }
        null
    }
    
    clone: func -> This {
        copy := new(name, token)
        if(getTypeArgs()) for(typeArg in getTypeArgs()) {
            copy addTypeArg(typeArg)
        }
        copy setRef(getRef())
        copy
    }
    
    dig: func -> Type {
        if(ref != null && ref instanceOf(CoverDecl)) {
            return ref as CoverDecl getFromType()
        }
        return null
    }
    
    inheritsFrom: func (t: Type) -> Bool {
        if(!t instanceOf(BaseType)) return false
        bt := t as BaseType
        if(   ref == null || !   ref instanceOf(TypeDecl)) return false
        if(bt ref == null || !bt ref instanceOf(TypeDecl)) return false
        
        return ref as TypeDecl inheritsFrom(bt ref as TypeDecl)
    }
    
    toString: func -> String {
        if(typeArgs == null) return getName()
        
        sb := Buffer new()
        sb append(getName())
        sb append("<")
        isFirst := true
        if(typeArgs) for(typeArg in typeArgs) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            sb append(typeArg toString())
        }
        sb append(">")
        return sb toString()
    }

}

SugarType: abstract class extends Type {
    
    inner: Type
    
    init: func ~sugarType (=inner, .token) { super(token) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    getRef: func -> Declaration   { inner getRef()  }
    setRef: func (d: Declaration) { inner setRef(d) }
    
    getTypeArgs: func -> List<VariableAccess> { inner getTypeArgs() }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        return (other instanceOf(class) ? inner getScore(other as SugarType inner) : NOLUCK_SCORE)
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
    
    write: func (w: AwesomeWriter, name: String) {
        inner write(w, null)
        if(!inner isGeneric()) w app("*")
        if(name != null) w app(' '). app(name)
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as PointerType inner equals(inner))
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        return super resolve(trail, res)
    }
    
    toString: func -> String { inner toString() + "*" }
    toMangledString: func -> String { inner toString() + "__star" }
    
    dereference : func -> This { inner }
    
    clone: func -> This { new(inner, token) }
    
}

ArrayType: class extends PointerType {
    
    expr : Expression = null
    
    init: func ~arrayType (.inner, =expr, .token) { super(inner, token) }
    
    write: func (w: AwesomeWriter, name: String) {
        inner write(w, null)
        if(name != null) w app(' '). app(name)
        if(expr != null) w app("["). app(expr). app("]")
        else             w app("[]")
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(expr == null) {
            //kiddo := BaseType new()
            //kiddo typeArgs add()
            //trail peek() replace()
        }
        
        return super resolve(trail, res)
        
    }
    
    toString: func -> String { inner toString() append(expr != null ? "[%s]" format(expr toString()) : "[]") }
    toMangledString: func -> String { inner toString() + "__array" }
    
}

ReferenceType: class extends SugarType {
    
    init: func ~pointerType (.inner, .token) { super(inner, token) }
    
    pointerLevel: func -> Int { inner pointerLevel() }
    refLevel:     func -> Int { inner refLevel() + 1 }
    
    write: func (w: AwesomeWriter, name: String) {
        inner write(w, null)
        w app("*")
        if(name != null) w app(' '). app(name)
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
