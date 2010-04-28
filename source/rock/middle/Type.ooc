import text/Buffer
import structs/[ArrayList, List]
import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, VariableDecl,
       Module, Import, CoverDecl, VariableAccess, Expression,
       InterfaceDecl, FunctionCall, NullLiteral
import BaseType
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
    
    /**
     * :return: true if the node supports type arguments and it's been
     * successfully added, false if not
     */
    addTypeArg: func (typeArg: VariableAccess) -> Bool { false }
    
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
            //printf("Failing %s (%s) vs %s (%s) with strict score %d\n", toString(), getRef() ? getRef() token toString() : "(unknown)",
            //                                                            other toString(), other getRef() ? other getRef() token toString() : "(unknown)", score)
            
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
    
    /** 
        Used in FunctionCall scoring - When we have a reftype, say, Int@,
        from the inside it should have type 'Int', but from the outside, 'Int*'.
        This converts Int@ to Int*.
        Note that the pointerLevel() for Int@ is 0, whereas for Int* it's 1.
    */
    refToPointer: func -> This {
        this
    }
    
    /**
        Search for a type argument, e.g. <T> in a type.
        This is less trivial than it sounds. In the simplest case, we have
        ArrayList<Int> for example, so T -> Int
        But in some other cases, we have Trail extends Stack<Node>
        and thus T -> Node.
        
        :return: The real type corresponding to a TypeArg, or null if none is found.
    */
    searchTypeArg: func (typeArgName: String, finalScore: Int@) -> Type {
        null
    }
    
}

TypeAccess: class extends Type {
    
    inner: Type
    
    init: func ~typeAccess (=inner, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitTypeAccess(this)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }
    
    write: func (w: AwesomeWriter, name: String) {}
    
    getName: func -> String { inner getName() }
    
    getTypeArgs: func -> List<VariableAccess> { inner getTypeArgs() }
    
    pointerLevel: func -> Int { inner pointerLevel() }
    
    equals: func (other: Type) -> Bool { inner equals(other) }
    
    getRef: func -> Declaration { inner getRef() }
    setRef: func (d: Declaration) { inner setRef(d) }
    
    clone: func -> Type { inner clone() }
    
    dereference: func -> Type { inner dereference() }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        inner getScoreImpl(other, scoreSeed)
    }
    
    dig: func -> Type { inner dig() }
    
    searchTypeArg: func (typeArgName: String, finalScore: Int@) -> Type {
        inner searchTypeArg(typeArgName, finalScore&)
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
        
        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
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
        if(!inner isGeneric()) w app('*')
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
        if(expr != null) {
            w app("_lang_array__Array")
            
            if(name != null) {
                w app(' '). app(name). app(" = _lang_array__Array_new(")
                inner write(w, null)
                w app(", "). app(expr). app(")")
                
                if(inner instanceOf(ArrayType)) {
                    w app(';'). nl(). app("{ int __i; for(__i = 0; __i < "). app(expr). app("; __i++) { "). nl()
                    inner as ArrayType write(w, name + "_sub")
                    w app(";"). nl(). app("_lang_array__Array_set("). app(name). app(", __i, "). app(inner). app(", "). app(name). app("_sub);").
                      app(" }}")
                }
            }
        } else {
            inner write(w, null)
            w app("[]")
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(expr == null) {
            kiddo := BaseType new("ArrayList", token)
            kiddo addTypeArg(VariableAccess new(getName(), token))
            kiddo resolve(trail, res)
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
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        inner getScoreImpl(other, scoreSeed)
    }
    
}
