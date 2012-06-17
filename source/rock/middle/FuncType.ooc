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

FuncType: class extends BaseType {

    argTypes := ArrayList<Type> new()
    varArg := VarArgType NONE
    typeArgDecls: ArrayList<VariableDecl>

    _returnType: Type = null
    returnType: Type {
        get { _returnType }
        set(x) {
            _returnType = x
            // Terribad.
            typeArgs set(1, VariableAccess new(x getName(), token))
        }
    }

    cached := ArrayList<Module> new()

    isClosure := false
    init: func ~funcType (.token) {
        // we rely on the Func type being defined in the sdk. One of the essentials!
        super("Func", token)

        // we also rely on it having <Context, Return>
        typeArgs = ArrayList<VariableAccess> new()
        typeArgs add(VariableAccess new("EmptyContext", token))
        typeArgs add(VariableAccess new("Int", token))
    }

    equals?: func (other: This) -> Bool {
        if(other class != this class) return false
        // FIXME compare argument's types, return type, etc.
        return true
    }

    getType: func -> Type { this }

    // should we throw an error or something?
    dereference : func -> This { null }

    realTypize: func (call: FunctionCall) -> Type {
        copy := This new(token)
        for(argType in argTypes) {
            copy argTypes add(argType realTypize(call))
        }
        copy returnType = returnType realTypize(call)
        copy varArg = varArg
        copy
    }

    clone: func -> This {
        copy := This new(token)
        copy argTypes addAll(argTypes)
        copy returnType = returnType
        copy varArg = varArg
        copy
    }

    addTypeArg: func ~decl (v: VariableDecl) {
        if (typeArgDecls == null) {
            typeArgDecls = ArrayList<VariableDecl> new()
        }
        typeArgDecls add(v)
    }

    getTypeArgs: func -> List<VariableDecl> {
        typeArgs
    }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {

        if(other instanceOf?(FuncType)) {
            fType := other as FuncType

            // not the same number of args? forget it
            if(fType argTypes getSize() != argTypes getSize()) {
                return NOLUCK_SCORE
            }

            // TODO: compare arg types (scores), return types, i otras cosas.
            return scoreSeed
        }

        if(other isCallable()) {
            // close enough.
            return scoreSeed / 2
        }

        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }

        return NOLUCK_SCORE
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        response := super(trail, res)
        if (!response ok()) return response

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

        if(typeArgDecls) for(typeArg in typeArgDecls) {
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

    isPointer: func -> Bool { true }
    isCallable: func -> Bool { true }

    dig: func -> Type { null }

    checkedDigImpl: func (list: List<Type>, res: Resolver) {}

}
