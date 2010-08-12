import structs/[List, ArrayList], text/Buffer

import ../backend/cnaughty/AwesomeWriter, ../frontend/BuildParams
import tinker/[Response, Resolver, Trail]

import Type, BaseType, VariableAccess, Declaration, CoverDecl, TypeDecl,
       Module, FunctionCall

FuncType: class extends Type {

    argTypes := ArrayList<Type> new()
    typeArgs := ArrayList<VariableAccess> new()
    varArg := false
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
        copy typeArgs addAll(typeArgs)
        for(argType in argTypes) {
            copy argTypes add(argType realTypize(call))
        }
        copy returnType = returnType realTypize
        copy varArg = varArg
        copy
    }

    clone: func -> This {
        copy := This new(token)
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

        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }

        if(other instanceOf?(FuncType)) {
            fType := other as FuncType

            // not the same number of args? forget it
            if(fType argTypes size() != argTypes size()) {
                return NOLUCK_SCORE
            }

            // TODO: compare arg types (scores), return types, i otras cosas.

            return scoreSeed
        }
        return NOLUCK_SCORE
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)

        if(typeArgs && !typeArgs empty?()) {
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

        if(!cached contains?(trail module())) {
            cached add(trail module())
            trail module() addFuncType(toMangledString(), this)
            res wholeAgain(this, "Added funcType!")
        }

        return Responses OK
    }

    toString: func -> String {
        b := Buffer new()
        isFirst := true

        b append("Func (")
        for(typeArg in typeArgs) {
            if(isFirst) isFirst = false
            else        b append(", ")
            b append(typeArg getName())
        }
        for(argType in argTypes) {
            if(isFirst) isFirst = false
            else        b append(", ")

            if(argType == null) { b append("<null arg type>"); continue }
            b append(argType toMangledString())
        }
        b append(')')
        if(returnType != null) {
            b append(" -> "). append(returnType toMangledString())
        }
        b toString()
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if(access getName() == "size") {
            // a func is the size of a pointer
            access expr = VariableAccess new("Pointer", token)
            return 0
        }

        super(access, res, trail)

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
