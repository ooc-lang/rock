import text/Buffer
import structs/[ArrayList, List]
import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, VariableDecl,
       Module, Import, CoverDecl, VariableAccess, Expression,
       InterfaceDecl, FunctionCall, NullLiteral
import tinker/[Response, Resolver, Trail]

voidType := BaseType new("void", nullToken)
voidType ref = BuiltinType new("void", nullToken)

Type: abstract class extends Expression {

    SCORE_SEED := const static 1024
    NOLUCK_SCORE := const static -100000
    
    init: func ~type (.token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitType(this) }
    
    pointerLevel: abstract func -> Int
    moreMagic:     func {} // FIXME: when one removes that function, rock segfaults - can you find out why?
    
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
        return false
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    clone: abstract func -> This
    
    reference:   func          -> This { p := PointerType new(this, token); p setRef(getRef()); p }
    dereference: abstract func -> This
    
    getTypeArgs: abstract func -> List<VariableAccess>
    
    getType: func -> This {
        getRef() ? getRef() getType() : null
    }

    getStrictScore: func (other: This) -> Int {
        score := getScoreImpl(other, This SCORE_SEED)
        if(score == -1) {
            // something needs resolving
            return -1
        }
        if(score != This SCORE_SEED) {
            // imperfect match, failing
            return This NOLUCK_SCORE
        }
        score
    }
    
    getScore: func (other: This) -> Int {
        bestScore := This NOLUCK_SCORE
        scoreSeed := This SCORE_SEED
        
        left := this
        while(left != null) {
            score := left getScoreImpl(other, scoreSeed)
            //printf(" >> Compared %s with %s, got score %d\n", left toString(), other toString(), score)
            if(score > bestScore) {
                bestScore = score
            }
            left = left dig()
            scoreSeed -= 1
        }
        return bestScore
    }
    
    isNumericType: func -> Bool {
        if(pointerLevel() != 0) return false
        
        // FIXME: that's quite ugly - and what about custom types?
        name := getName()
        if ((
           name == "Int"   || name == "UInt"  || name == "Short" ||
		   name == "UShort"|| name == "Long"  || name == "ULong" ||
		   name == "LLong" || name == "ULLong"|| name == "Char"  ||
		   name == "UChar" || name == "Int8"  || name == "Int16" ||
		   name == "Int32" || name == "Int64" || name == "UInt8" ||
		   name == "UInt16"|| name == "UInt32"|| name == "UInt64"||
		   name == "SizeT" || name == "Float" || name == "Double"
		)) return true
        
        down := dig()
        if(down) return down isNumericType()
        
        return false
    }
    
    isPointer: func -> Bool { (pointerLevel() == 1) || (getName() == "Pointer") }
    
    getScoreImpl: abstract func (other: This, scoreSeed: Int) -> Int
    
    inheritsFrom: func (t: This) -> Bool { false }
    
    dig: abstract func -> This
    
    // Used in FunctionCall scoring - When we have a reftype, say, Int@,
    // from the inside it should have type 'Int', but from the outside, 'Int*'.
    // This converts Int@ to Int*.
    // Note that the pointerLevel() for Int@ is 0, whereas for Int* it's 1.
    refToPointer: func -> This {
        this
    }
    
}

FuncType: class extends Type {
    
    argTypes := ArrayList<Type> new()
    typeArgs := ArrayList<VariableAccess> new()
    varArg := false
    returnType : Type = null
    cached := false
    
    init: func ~funcType (.token) {
        super(token)
        CoverDecl new("", token)
    }
    
    write: func (w: AwesomeWriter, name: String) {
        w app (toMangledString())
        if(name) w app(' '). app(name)
    }
    
    pointerLevel: func -> Int { 0 }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        // FIXME compare argument's types, return type, etc.
        return true
    }
    
    getName: func -> String { "Func" }
    
    getType: func -> Type { this }
    getRef: func -> Declaration { this }
    setRef: func (d: Declaration) {}
    
    // should we throw an error or something?
    dereference : func -> This { null }
    
    clone: func -> This {
        copy := new(token)
        copy typeArgs addAll(typeArgs)
        copy argTypes addAll(argTypes)
        copy returnType = returnType
        copy varArg = varArg
        copy
    }
    
    getTypeArgs: func -> List<VariableAccess> { typeArgs }
    
    addTypeArg: func (typeArg: VariableAccess) -> Bool {
        if(!typeArgs) typeArgs = ArrayList<VariableAccess> new()
        typeArgs add(typeArg); true
    }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf(FuncType)) {
            return scoreSeed
        }
        return This NOLUCK_SCORE
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)
        
        if(typeArgs && !typeArgs isEmpty()) {
            for(typeArg in typeArgs) {
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
            }
        }
        
        for(argType in argTypes) {
            response := argType resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        if(returnType != null) {
            response := returnType resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        if(!cached) {
            cached = true
            trail module() addFuncType(toMangledString(), this)
            res wholeAgain(this, "Added funcType!")
        }
        
        return Responses OK
    }
    
    toMangledString: func -> String {
        b := Buffer new()
        b append("__FUNC__")
        for(typeArg in typeArgs) {
            /*
            b append('_'). append(typeArg getRef() as Type toMangledString())
            */
            b append('_'). append(typeArg getName())
        }
        for(argType in argTypes) {
            b append('_'). append(argType toMangledString())
        }
        if(returnType != null) {
            b append('_'). append(returnType toMangledString())
        }
        b toString()
    }
    
    isPointer: func -> Bool { true }
    
    dig: func -> Type { null }
    
}

BaseType: class extends Type {

    ref: Declaration = null
    name: String
    
    typeArgs: List<VariableAccess> = null
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    
    isPointer: func -> Bool { name == "Pointer" }
    
    write: func (w: AwesomeWriter, name: String) {
        if(getRef() == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        match {
            case getRef() instanceOf(InterfaceDecl)=> writeInterfaceType(w, getRef())
            case getRef() instanceOf(TypeDecl)     => writeRegularType  (w, getRef())
            case getRef() instanceOf(VariableDecl) => writeGenericType  (w, getRef())
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
    
    addTypeArg: func (typeArg: VariableAccess) -> Bool {
        if(!typeArgs) typeArgs = ArrayList<VariableAccess> new()
        typeArgs add(typeArg); true
    }
    
    getName: func -> String { name }
    
    suggest: func (decl: Declaration) -> Bool {
        ref = decl
        if(name == "This" && getRef() instanceOf(TypeDecl)) {
            // not exactly sure how good an idea it is
            tDecl := getRef() as TypeDecl
            name = tDecl getName()
        }
        return true
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        if(isResolved()) return Responses OK
        
        if(!getRef()) {
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth, Node)
                node resolveType(this)
                if(getRef()) break // break on first match
                depth -= 1
            }
        }
        
        if(getRef() == null) {
            if(res fatal) {
                token throwError("Can't resolve type %s!" format(getName()))
            }
            if(res params veryVerbose) {
                printf("     - type %s still not resolved, looping (ref = %p)\n", name, getRef())
            }
            return Responses LOOP
        } else if(getRef() instanceOf(TypeDecl)) {
            tDecl := getRef() as TypeDecl
            if(!tDecl isMeta && !tDecl getTypeArgs() isEmpty()) {
                if(typeArgs == null || typeArgs size() != tDecl getTypeArgs() size()) {
                    token throwError("Missing type parameters for "+toString()+". It should match "+tDecl getInstanceType() toString())
                }
            }
        }
        
        if(typeArgs) {
            trail push(this)
            for(typeArg in typeArgs) {
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
            }
            trail pop(this)
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool {
        if(getRef() == null) return false
        if(typeArgs == null) return true
        for(typeArg in typeArgs) if(!typeArg isResolved()) {
            return false
        }
        return true
    }
    
    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}
    
    getTypeArgs: func -> List<VariableAccess> { typeArgs }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }
        if(isGeneric() && other isPointer()) {
            // a generic value is a match for a pointer
            return scoreSeed / 2
        }
        if(isPointer() && other getRef() instanceOf(ClassDecl)) {
            // objects are references in ooc
            return scoreSeed / 2
        }
        if(getRef() instanceOf(ClassDecl) && other isPointer()) {
            // objects are still references in ooc
            return scoreSeed / 2
        }
        if(isPointer() && other getGroundType() isPointer()) {
            // two pointers = okay
            return scoreSeed / 2
        }
        if(other instanceOf(BaseType)) {
            if(getRef() == null || other getRef() == null) return -1
            
            if(getRef() == other getRef()) {
                // perfect match
                return scoreSeed
            }
            
            if(getName() == other getName()) {
                // *sigh* I wish we didn't have to do that
                return scoreSeed / 2
            }
            
            if(getRef() instanceOf(TypeDecl) && other getRef() instanceOf(TypeDecl)) {
                inheritsScore := getRef() as TypeDecl inheritsScore(other getRef() as TypeDecl, scoreSeed)
                
                // something needs resolving
                if(inheritsScore == -1) return inheritsScore
                
                // cool, a match =)
                if(inheritsScore > 0) return inheritsScore
            }
            
            if(isNumericType() && other isNumericType()) {
                // Only half a match - it's not too good to mix integer types. Maybe we need more safety here?
                return scoreSeed / 2
            }
        }
        
        return This NOLUCK_SCORE // no luck.
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
        if(getRef() != null && getRef() instanceOf(CoverDecl)) {
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
    
    replace: func (oldie, kiddo: Node) -> Bool {
        if(typeArgs) return typeArgs replace(oldie, kiddo)
        false
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
        if(other instanceOf(class)) {
            score := inner getScore(other as SugarType inner)
            if(score >= -1) return score
        }
        if(pointerLevel() == 1 && other isPointer()) {
            // void pointer, half match!
            return scoreSeed / 2
        }
        return This NOLUCK_SCORE
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
        return super(trail, res)
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
            kiddo := BaseType new("ArrayList", token)
            kiddo addTypeArg(VariableAccess new(getName(), token))
            parent := trail peek()
            
            if(!parent replace(this, kiddo)) {
                printf("Couldn't replace %s with %s in %s, trail = %s\n", toString(), kiddo toString(), parent toString(), trail toString())
            }
            
            if(parent instanceOf(VariableDecl)) {
                vd := parent as VariableDecl
                if(!vd isArg && vd getType() == kiddo) {
                    fCall := FunctionCall new(kiddo, "new", token)
                    vd setExpr(fCall)
                }
            }
        } else {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }
        
        return super(trail, res)
        
    }
    
    toString: func -> String { inner toString() append(expr != null ? "[%s]" format(expr toString()) : "[]") }
    toMangledString: func -> String { inner toString() + "__array" }
    
}

ReferenceType: class extends SugarType {
    
    init: func ~referenceType (.inner, .token) { super(inner, token) }
    
    pointerLevel: func -> Int { inner pointerLevel() }
    
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
    
    refToPointer: func -> Type {
        PointerType new(inner refToPointer(), token)
    }
    
}
