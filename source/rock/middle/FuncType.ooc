import structs/[List, ArrayList]

import ../backend/cnaughty/AwesomeWriter, ../frontend/BuildParams
import tinker/[Response, Resolver, Trail]

import Type, BaseType, VariableAccess, Declaration, CoverDecl, TypeDecl,
       Module, FunctionCall, VariableDecl

VarArgType: enum {
    /** No variable arguments at all */
    NONE
    /** ooc-style variable arguments */
    OOC
    /** C-style variable arguments */
    C
}

FuncType: class extends Type {

    argTypes := ArrayList<Type> new()
    typeArgs: ArrayList<VariableDecl>
    varArg := VarArgType NONE
    returnType : Type = null
    cached := ArrayList<Module> new()

    isClosure := false
    init: func ~funcType (.token) {
        super(token)
        CoverDecl new("", token)
    }

    write: func (w: AwesomeWriter, name: String) {
        w app("lang_types__Closure")
        if(name) w app(' '). app(name)
    }

    pointerLevel: func -> Int { 0 }

    equals?: func (other: This) -> Bool {
        if(other class != this class) return false
        // FIXME compare argument's types, return type, etc.
        return true
    }

    getName: func -> String { "Func" }

    getType: func -> Type { this }
    getRef: func -> Declaration { this as Declaration /* hmm that's wrong. FuncType doesn't inherit from Declaration :x */ }
    setRef: func (d: Declaration) {}

    // should we throw an error or something?
    dereference : func -> This { null }

    realTypize: func (call: FunctionCall) -> Type {
        copy := This new(token)
        if(typeArgs) {
            typeArgs each(|typeArg|
                copy addTypeArg(typeArg)
            )
        }

        argTypes each(|argType|
            copy argTypes add(argType realTypize(call))
        )

        copy returnType = returnType ? returnType realTypize(call) : null
        copy varArg = varArg
        copy isClosure = isClosure
        copy
    }

    clone: func -> This {
        copy := This new(token)

        if(typeArgs) {
            typeArgs each(|typeArg|
                copy addTypeArg(typeArg clone())
            )
        }

        argTypes each(|argType|
            copy argTypes add(argType clone())
        )

        copy returnType = returnType ? returnType clone() : null
        copy varArg = varArg
        copy isClosure = isClosure
        copy
    }

    getTypeArgs: func -> List<VariableDecl> { typeArgs }

    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        if(!typeArgs) typeArgs = ArrayList<VariableDecl> new()
        typeArgs add(typeArg); true
    }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {

        if(other isPointer()) {
            // close enough.
            return scoreSeed / 2
        }

        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }

        if(other instanceOf?(FuncType)) {
            fType := other as FuncType

            // not the same number of args? forget it
            if(fType argTypes getSize() != argTypes getSize()) {
                return NOLUCK_SCORE
            }

            // Find out whether a lambda is involved
            closure? := isClosure || fType isClosure
            lambda? := closure? && (!argTypes contains?(|arg| arg != null) || !fType argTypes contains?(|arg| arg != null))

            // If one of our function types comes from a closure, we don't care about return types and typeArgs! :D
            if(!lambda?) {
                // Check that both function types have/dont have return types
                if(returnType && !returnType void? && (!fType returnType || fType returnType void?) ||
                   (!returnType || returnType void?) && fType returnType && !fType returnType void?) return NOLUCK_SCORE

                // Also, lets make sure we have the same amount of generic types
                if(typeArgs && !fType typeArgs || !typeArgs && fType typeArgs ||
                   typeArgs && typeArgs getSize() != fType typeArgs getSize()) return NOLUCK_SCORE
            }

            parts := argTypes getSize() + (!lambda? && returnType && !returnType void? ? 1 : 0)
            finalScore := 0

            // Void functions match perfectly :)
            if(parts == 0) finalScore = scoreSeed
            // Compare argument types
            for(i in 0 .. argTypes getSize()) {
                // For closures, we just don't care about the argument types, as we do not have information on them
                if(lambda?) {
                    finalScore += scoreSeed/parts
                    continue
                }

                if(!argTypes[i] || !fType argTypes[i]) return -1
                score := argTypes[i] getScoreImpl(fType argTypes[i], scoreSeed)
                if(score == -1) return -1
                else if(score == NOLUCK_SCORE) return score
                finalScore += score/parts
            }

            // Compare return type
            if(returnType && !returnType void? && parts > 0) {
                score := returnType getScoreImpl(fType returnType, scoreSeed)
                if(score == -1) return -1
                else if(score == NOLUCK_SCORE) return score
                finalScore += score/parts
            }

            return finalScore
        }
        return NOLUCK_SCORE
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)

        if(typeArgs) for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        for(argType in argTypes) {
            if(!argType) {
                "Got null argType in FuncType %s" printfln(toString())
                continue
            }
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

        if(!cached contains?(trail module())) {
            cached add(trail module())
            trail module() addFuncType(toMangledString(), this)
            res wholeAgain(this, "Added funcType!")
        }

        return Response OK
    }

    toString: func -> String {
        b := Buffer new()

        b append("Func ")
        isFirst := true
        if(typeArgs) {
            b append("<")
            for(typeArg in typeArgs) {
                if(isFirst) isFirst = false
                else        b append(", ")
                b append(typeArg getName())
            }
            b append("> ")
        }
        b append("(")
        isFirst = true
        for(argType in argTypes) {
            if(isFirst) isFirst = false
            else        b append(", ")

            if(argType == null) { b append("<?>"); continue }
            b append(argType toMangledString())
        }
        b append(')')
        if(returnType != null && !returnType void?) {
            b append(" -> "). append(returnType toMangledString())
        }
        b toString()
    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {

        if(typeArgs) for(typeArg in typeArgs) {
            if(typeArg name == type name) {
                type suggest(typeArg)
                return 0
            }
        }

        0

    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if(access getName() == "size") {
            // a func is the size of a pointer
            access expr = VariableAccess new("Pointer", token)
            return 0
        }

        if(typeArgs) for(typeArg in typeArgs) {
            if(access name == typeArg name) {
                if(access suggest(typeArg)) return 0
            }
        }

        super(access, res, trail)

    }

    toMangledString: func -> String {
        b := Buffer new()
        b append("__FUNC__")
        if(typeArgs) for(typeArg in typeArgs) {
            b append('_'). append(typeArg getName())
        }
        for(argType in argTypes) {
            if(argType == null) { b append("_nullArgType"); continue }
            b append('_'). append(argType toMangledString())
        }
        if(returnType != null) {
            b append('_'). append(returnType toMangledString())
        }
        b toString()
    }

    isPointer: func -> Bool { false }

    dig: func -> Type { null }

    checkedDigImpl: func (list: List<Type>, res: Resolver) {}

}
