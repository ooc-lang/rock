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
    searchTypeArg: func (typeArgName: String) -> Type {
        null
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
        if(other isPointer()) {
            // close enough.
            return scoreSeed / 2
        }
        
        // TODO: compare args, return types, i otras cosas.
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
    
}
