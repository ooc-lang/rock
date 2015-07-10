import structs/[ArrayList, List]
import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Node, Visitor, Declaration, TypeDecl, ClassDecl, VariableDecl,
       Module, Import, CoverDecl, VariableAccess, Expression,
       InterfaceDecl, FunctionCall, NullLiteral
import BaseType
import tinker/[Response, Resolver, Trail]

voidType := VoidType new()

NumericState: enum {
    UNKNOWN, YES, NO
}

Type: abstract class extends Expression {

    SCORE_SEED := const static 1024
    NOLUCK_SCORE := const static -100000

    owner: Expression = null

    init: func ~type (.token) {
        super(token)
    }

    void?: Bool { get { this == voidType } }

    accept: func (visitor: Visitor) { visitor visitType(this) }

    pointerLevel: abstract func -> Int

    write: abstract func (w: AwesomeWriter, name: String)

    equals?: abstract func (other: This) -> Bool

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

    isResolved: func -> Bool {
      getRef() != null
    }

    /**
     * Get the reference of this type (usually a TypeDecl,
     * but could be a VariableDecl, if we're a generic type
     * for instance.)
     */
    getRef: abstract func -> Declaration

    /**
     * Set the reference of this type. May be ignored
     * on some subclasses that have computed refs.
     */
    setRef: abstract func (d: Declaration)

    /**
     * @return true if 1) this type has a ref, AND 2) it's a VariableDecl.
     * Not reliable if you don't check that it has a ref first, it might
     * just return false because it's not resolved yet.
     */
    isGeneric: func -> Bool {
        if(getRef()) {
            return getRef() instanceOf?(VariableDecl)
        }
        return false
    }

    /**
     * Attempts to find the 'real' type of a generic type (ie. this)
     * from the info given to us by function call (e.g. is it a method call
     * on a generic class?, is it a call to a top-level generic function with
     * explicit typeArgs? etc.)
     */
    realTypize: abstract func (call: FunctionCall) -> Type

    /**
     * Types usually have no children, can't replace anything
     */
    replace: func (oldie, kiddo: Node) -> Bool { false }

    /**
     * Type subclasses should definitely implement clone — 'T' might
     * mean different things in different cover template instances, for instance
     *
     * This method does not conserve the reference, so the type will have to
     * be resolved again (on purpose).
     */
    clone: abstract func -> This

    /**
     * A twist on `clone`, that keeps the ref.
     */
    cloneWithRef: func -> This {
        copy := clone()
        copy setRef(getRef())
        copy
    }

    /**
     * @return `T*` for type `T`
     */
    reference: func -> This {
        PointerType new(this, token)
    }
    dereference: abstract func -> This

    /**
     * @return true if the node supports type arguments and it's been
     * successfully added, false if not
     */
    addTypeArg: func (typeArg: TypeAccess) -> Bool { false }

    /**
     * typeArgs are specified between chevrons, e.g. in `Foo<K, V>`,
     * K and V are the typeArgs of Foo.
     *
     * @return a list of typeArgs, or null if none (to avoid instanciating
     * a list for every little non-generic type)
     */
    getTypeArgs: abstract func -> List<TypeAccess>

    /**
     * The type of a type is.. a meta-type.
     *
     * Let's say we have:
     *
     *   rita := Dog new()
     *
     * Then 'rita' is a VariableAccess, which type is 'Dog',
     * and the type of 'Dog' is 'DogClass' (which inherits from 'Class')
     */
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
        isIntegerType() || isFloatingPointType()
    }

    isFloatingPointType: func -> Bool {
        getFloatingPointState() == NumericState YES
    }

    getTheoreticalTypeWidth: func -> Int {
        0
    }

    isIntegerType: func -> Bool {
        getIntegerState() == NumericState YES
    }

    getIntegerState: func -> NumericState {
        NumericState NO
    }

    getFloatingPointState: func -> NumericState {
        NumericState NO
    }

    isPointer: func -> Bool { false }

    getScoreImpl: abstract func (other: This, scoreSeed: Int) -> Int

    inheritsFrom?: func (t: This) -> Bool { false }

    dig: abstract func -> This

    /**
        Check for any loop in cover declaration
     */
    checkedDig: func (res: Resolver) {
        checkedDigImpl(ArrayList<Type> new(), res)
    }

    checkedDigImpl: abstract func (list: List<Type>, res: Resolver)

    /**
     * Used in FunctionCall scoring - When we have a reftype, say, Int@,
     * from the inside it should have type 'Int', but from the outside, 'Int*'.
     * This converts Int@ to Int*.
     * Note that the pointerLevel() for Int@ is 0, whereas for Int* it's 1.
     */
    refToPointer: func -> This {
        this
    }

    /**
     * Search for a type argument, e.g. <T> in a type.
     * This is less trivial than it sounds. In the simplest case, we have
     * ArrayList<Int> for example, so T -> Int
     * But in some other cases, we have Trail extends Stack<Node>
     * and thus T -> Node.
     *
     * @return The real type corresponding to a TypeArg, or null if none is found.
     */
    searchTypeArg: func (typeArgName: String, finalScore: Int@) -> Type {
        null
    }

    templateAbsolute: func -> This {
        clone()
    }

}

TypeAccess: class extends Type {

    inner: Type

    init: func ~typeAccess (=inner, .token) {
        if(!inner) raise("Creating null typeAccess")
        if(inner == this) raise("Created cyclic typeAccess")
        super(token)
    }

    init: func ~fromVarDecl (vDecl: VariableDecl, .token) {
        super(token)
        inner = BaseType new(vDecl getName(), token)
        inner setRef(vDecl)
    }

    accept: func (visitor: Visitor) {
        visitor visitTypeAccess(this)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)
        response := inner resolve(trail, res)
        trail pop(this)
        response
    }

    write: func (w: AwesomeWriter, name: String) {}

    getName: func -> String { inner getName() }

    getTypeArgs: func -> List<TypeAccess> { inner getTypeArgs() }

    pointerLevel: func -> Int { inner pointerLevel() }

    equals?: func (other: Type) -> Bool { inner equals?(other) }

    getRef: func -> Declaration { inner getRef() }
    setRef: func (d: Declaration) { inner setRef(d) }

    clone: func -> This {
        copy := new(inner clone(), token)
        copy owner = owner
        copy
    }

    dereference: func -> Type { inner dereference() }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        inner getScoreImpl(other, scoreSeed)
    }

    dig: func -> Type { inner dig() }

    checkedDigImpl: func (list: List<Type>, res: Resolver) {
        inner checkedDigImpl(list, res)
    }

    searchTypeArg: func (typeArgName: String, finalScore: Int@) -> Type {
        inner searchTypeArg(typeArgName, finalScore&)
    }

    realTypize: func (call: FunctionCall) -> Type {
        diff := inner realTypize(call)
        if(diff != inner) {
            return new(diff, token)
        }
        this
    }

    toString: func -> String {
        inner toString()
    }

}

/**
 * Common base class for PointerType and ReferenceType, since they're both
 * sugarcoated versions of an inner type (at least that's why it's named so').
 */
SugarType: abstract class extends Type {

    /**
     * The `Int` to our `Int*` or `Int&`
     */
    inner: Type

    init: func ~sugarType (=inner, .token) { super(token) }

    resolve: func (trail: Trail, res: Resolver) -> Response { inner resolve(trail, res) }

    getRef: func -> Declaration   { inner getRef()  }
    setRef: func (d: Declaration) { inner setRef(d) }

    getTypeArgs: func -> List<TypeAccess> { inner getTypeArgs() }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf?(class)) {
            score := inner getScore(other as SugarType inner)
            if(score >= -1) return score
        }

        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }

        if(pointerLevel() >= 1 && other isPointer()) {
            // void pointer, a partial match!
            // The more levels our pointer is, the less of a match we found! :D
            return scoreSeed / (2 * pointerLevel())
        }

        if(other getRef() instanceOf?(CoverDecl)) {
            dug := other dig()
            if(dug) return getScoreImpl(dug, scoreSeed / 2)
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

    checkedDigImpl: func (list: List<Type>, res: Resolver) {
        inner checkedDigImpl(list, res)
    }

    clone: abstract func -> This

    realTypize: func (call: FunctionCall) -> Type {
        diff := inner realTypize(call)
        if(diff != inner) {
            copy := clone()
            copy inner = diff
            return copy
        }
        this
    }

}

PointerType: class extends SugarType {

    init: func ~pointerType (.inner, .token) { super(inner, token) }

    pointerLevel: func -> Int { inner pointerLevel() + 1 }

    isPointer: func -> Bool { inner pointerLevel() == 0 && inner void? }

    isResolved: func -> Bool {
        super() && inner isResolved()
    }

    write: func (w: AwesomeWriter, name: String) {
        if(inner instanceOf?(ArrayType)) inner as ArrayType write(w, null, true)
        else inner write(w, null)
        if(!inner isGeneric()) w app('*')
        if(name != null) w app(' '). app(name)
    }

    equals?: func (other: This) -> Bool {
        if(other class != this class) return false

        other as PointerType inner equals?(inner)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        return super(trail, res)
    }

    toString: func -> String { inner toString() + "*" }
    toMangledString: func -> String { inner toString() + "__star" }

    dereference: func -> Type { inner }

    clone: func -> Type {
       new(inner clone(), token)
    }

}

ArrayType: class extends PointerType {

    expr : Expression = null
    realType := static BaseType new("Array", nullToken)

    init: func ~arrayType (.inner, =expr, .token) { super(inner, token) }

    setRef: func (ref: Declaration) {
        Exception new(This, "Trying to set ref of an ArrayType! wtf? ref (%s) = %s" format(ref class name, ref toString())) throw()
    }
    getRef: func -> Declaration {
        This realType getRef()
    }

    isResolved: func -> Bool {
        inner isResolved() && This realType isResolved()
    }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other instanceOf?(class)) {
            score := inner getScore(other as SugarType inner)
            if(score >= -1) return score
        }

        return This NOLUCK_SCORE
    }

    write: func~_true(w: AwesomeWriter, name: String, forceStars?: Bool) {
        if(expr == null) {
            w app("_lang_array__Array")
            if(name != null) {
                w app(' '). app(name)
            }
        } else if(forceStars?) {
            // Nested array declaration
            base := inner
            while(base instanceOf?(This)) {
                base = base as This inner
            }
            base write(w, null)
            stars := ""
            pointerLevel() times(|| stars = stars append('*'))
            w app(stars)
            if(name) w app(' ') . app(name)
        } else {
            inner write(w, null)
            w app(' ')
            if(name) w app(name)
            if(expr) w app('['). app(expr). app(']')
            else     w app('*')
        }
    }

    write: func (w: AwesomeWriter, name: String) {
        write~_true(w, name, false)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if(!This realType resolve(trail, res) ok()) {
            return Response LOOP
        }

        if(expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }

        return super(trail, res)

    }

    clone: func -> This {
        new(inner clone(), expr ? expr clone() : null, token)
    }

    exprLessClone: func -> This {
        copy := clone()

        current := copy as Type
        while(current instanceOf?(ArrayType)) {
            innerType := current as ArrayType
            innerType expr = null
            current = innerType inner
        }

        copy
    }

    toString: func -> String {
        inner toString() + match(expr) {
            case null => "[]"
            case      => "[%s]" format(expr toString())
        }
    }
    toMangledString: func -> String { inner toString() + "__array" }

    isPointer: func -> Bool { false }

}

ReferenceType: class extends SugarType {

    init: func ~referenceType (.inner, .token) { super(inner, token) }

    pointerLevel: func -> Int { inner pointerLevel() }

    write: func (w: AwesomeWriter, name: String) {
        inner write(w, null)
        w app("*")
        if(name != null) w app(' '). app(name)
    }

    equals?: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as PointerType inner equals?(inner))
    }

    toString: func -> String { inner toString() + "@" }
    toMangledString: func -> String { inner toString() + "__star" }

    dereference : func -> Type { inner dereference() }

    clone: func -> Type {
        new(inner clone(), token)
    }

    /**
     * Convert all ReferenceType(s) to PointerType(s), all the way down
     */
    refToPointer: func -> Type {
        PointerType new(inner refToPointer(), token)
    }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        inner getScoreImpl(other, scoreSeed)
    }

}
