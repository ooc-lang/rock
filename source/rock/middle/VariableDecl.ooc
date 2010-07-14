import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument, BinaryOp, Cast, Module,
       Block, Scope, FunctionDecl, Argument, BaseType, FuncType, Statement,
       NullLiteral, Tuple, TypeList, VariableDecl
import tinker/[Response, Resolver, Trail]
import ../frontend/BuildParams

VariableDecl: class extends Declaration {

    name = "", fullName = null, doc = "" : String

    type: Type
    expr: Expression
    owner: TypeDecl

    isArg := false
    isGlobal := false
    isConst := false
    isStatic := false
    isProto := false
    externName: String = null
    unmangledName: String = null

    /** if this VariableDecl is a Func, it can be called! */
    fDecl : FunctionDecl = null

    init: func ~vDecl (.type, .name, .token) {
        init(type, name, null, token)
    }

    init: func ~vDeclWithAtom (=type, =name, =expr, .token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

    setType: func(=type) {}
    getType: func -> Type { type }


    getName: func -> String { name }

    toString: func -> String {
        "%s : %s%s" format(
            name,
            type ? type toString() : "<unknown type>",
            expr ? " = " + expr toString() : ""
        )
    }

    /** If `true`, the property should not be added to the instance struct as a member.
        Ordinary variables never are virtual. Properties can be.
      */
    isVirtual: func -> Bool { false }

    setOwner: func (=owner) {}
    getOwner: func -> TypeDecl { owner }

    setExpr: func (=expr) {}
    getExpr: func -> Expression { expr }

    isStatic: func -> Bool { isStatic }
    setStatic: func (=isStatic) {}

    isConst: func -> Bool { isConst }
    setConst: func (=isConst) {}

    isProto: func -> Bool { isProto }
    setProto: func (=isProto) { "%s is now proto!" format(name) println() }

    isGlobal: func -> Bool { isGlobal }
    setGlobal: func (=isGlobal) {}

    isArg: func -> Bool { isArg }

    getExternName: func -> String { externName }
    setExternName: func (=externName) {}
    isExtern: func -> Bool { externName != null }
    isExternWithName: func -> Bool {
        (externName != null) && !(externName isEmpty())
    }

    getUnmangledName: func -> String { unmangledName isEmpty() ? name : unmangledName }
    setUnmangledName: func (=unmangledName) {}
    isUnmangled: func -> Bool { unmangledName != null }
    isUnmangledWithName: func -> Bool {
        (unmangledName != null) && !(unmangledName isEmpty())
    }

    getFullName: func -> String {
        if(fullName == null) {
            if(isUnmangled()) {
                fullName = getUnmangledName()
            } else if(isExtern()) {
                if(isExternWithName()) {
                    fullName = externName
                } else {
                    fullName = name
                }
            } else {
                if(!isGlobal()) {
                    fullName = name
                } else {
                    fullName = "%s__%s" format(token module getUnderName(), name)
                }
            }
        }
        fullName
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        // FIXME: This, huh, shouldn't be needed at all, right?
        // ie. it should all be handled in Scope anyway, I think.
        if(name == access name) {
            access suggest(this)
        }

        0
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        //if(res params veryVerbose) printf("Resolving variable decl %s\n", toString())

        if(expr) {
            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(type == null && expr != null) {
            // infer the type
            type = expr getType()
            if(type == null) {
                trail pop(this)
                res wholeAgain(this, "must determine type of %s\n" format(toString()))
                return Responses OK
            }
        }

        if(type != null) {
            //if(res params veryVerbose) printf("Resolving type %s, of type %s\n", type toString(), type class name)
            response := type resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(fDecl != null) {
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        parent := trail peek()
        {
            if(!parent isScope() && !parent instanceOf(TypeDecl)) {
                //println("oh the parent of " + toString() + " isn't a scope but a " + parent class name)
                //println("trail = " + trail toString())

                result := trail peek() replace(this, VariableAccess new(this, token))
                if(!result) {
                    token throwError("Couldn't replace %s with a varAcc in %s, trail = %s" format(toString(), trail peek() toString(), trail toString()))
                }

                idx := trail findScope()
                scope := trail get(idx) as Scope

                parent := trail get(idx + 1, Node)

                if(parent instanceOf(FunctionCall)) {
                    result = trail addBeforeInScope(parent as Statement, this)
                } else {
                    block := Block new(token)
                    block getBody() add(this)
                    block getBody() add(parent as Statement)

                    result = scope replace(trail get(idx + 1), block)
                }

                if(!result) {
                    token throwError("Couldn't unwrap " + toString() + " , trail = " + trail toString())
                }

                res wholeAgain(this, "parent isn't scope nor typedecl, unwrapped")
                //return Responses OK
                return Responses LOOP
            }
        }

        if(expr != null) {
            realExpr := expr
            while(realExpr instanceOf(Cast)) {
                realExpr = realExpr as Cast inner
            }
            if(realExpr instanceOf(FunctionCall)) {
                fCall := realExpr as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl || !fDecl getReturnType() isResolved()) {
                    res wholeAgain(this, "fCall isn't resolved.")
                    return Responses OK
                }

                //if(fDecl getReturnType() isGeneric()) {
                if(!fDecl getReturnArgs() isEmpty()) {
                    if(fDecl getReturnType() instanceOf(TypeList)) {
                        type = fDecl getReturnType() as TypeList types get(0)
                        "Inferred type of %s to %s from TypeList." printfln(toString(), type toString())
                    }
                    ass := BinaryOp new(VariableAccess new(this, token), realExpr, OpTypes ass, token)
                    if(!trail addAfterInScope(this, ass)) {
                        token throwError("Couldn't add a " + ass toString() + " after a " + toString() + ", trail = " + trail toString())
                    }
                    expr = null
                }
            }
        } else { // Set pointer references to NULL
            if (!owner && trail peek() instanceOf(Scope)) { // don't touch a member-variable or an argument
                t := getType()
                if (!t) {
                    res wholeAgain(this, "Need Type.")
                    return Responses OK
                }
                reference := t getRef()
                if (!reference || !getType()) {
                    res wholeAgain(this, "Need reference.")
                    return Responses OK
                }
                if (t isPointer() || reference instanceOf(ClassDecl)) { // Pointer OR object
                    expr = NullLiteral new(token)
                }
            }
        }

        if(!isArg && type != null && type isGeneric() && type pointerLevel() == 0) {
            if(expr != null) {
                if(expr instanceOf(FunctionCall) && expr as FunctionCall getName() == "gc_malloc") return Responses OK

                ass := BinaryOp new(VariableAccess new(this, token), expr, OpTypes ass, token)
                if(!trail addAfterInScope(this, ass)) {
                    token throwError("Couldn't add a " + ass toString() + " after a " + toString() + ", original expr = " + expr toString() + " trail = " + trail toString())
                }
                expr = null
            }
            fCall := FunctionCall new("gc_malloc", token)
            tAccess := VariableAccess new(type getName(), token)
            sizeAccess := VariableAccess new(tAccess, "size", token)
            fCall getArguments() add(sizeAccess)
            expr = fCall
            res wholeAgain(this, "just set expr to gc_malloc cause generic!")
        }

        return Responses OK

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case type => type = kiddo; true
            case => false
        }
    }

    getFunctionDecl: func -> FunctionDecl {
        if(fDecl == null) {
            if(getType() instanceOf(FuncType)) {
                fType := getType() as FuncType
                fDecl = FunctionDecl new(name, token)
                if(owner) fDecl setOwner(owner)
                if(fType typeArgs != null && !fType typeArgs isEmpty()) {
                    classType := BaseType new("Class", fType token)
                    for(typeArg in fType typeArgs) {
                        vDecl := VariableDecl new(classType, typeArg name, typeArg token)
                        fDecl typeArgs add(vDecl)
                        typeArg setRef(vDecl)
                    }
                }
                for(argType in fType argTypes) {
                    fDecl args add(Argument new(argType, "", token))
                }
                if(fType varArg) {
                    fDecl args add(VarArg new(token))
                }
                if(fType returnType != null) {
                    fDecl setReturnType(fType returnType)
                }
                fDecl vDecl = this
            } else if(getType() getName() == "Closure") {
                fDecl = FunctionDecl new(name, token)
                fDecl args add(VarArg new(token))
                fDecl vDecl = this
            }
        }
        return fDecl
    }

    isMember: func -> Bool { owner != null }

}

VariableDeclTuple: class extends VariableDecl {

    tuple: Tuple

    init: func ~vdTuple (.type, =tuple, .token) {
        init~vDecl (type, "<tuple>", token)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        token printMessage("Got a VariableDeclTuple, and expr is %s!" format(expr ? expr toString() : "(nil)"), "INFO")

        expr resolve(trail, res)

        match {
            case expr == null =>
                token throwError("VariableDeclTuples need an expression. This should never happen")
            case expr instanceOf(FunctionCall) =>
                fCall := expr as FunctionCall
                if(fCall getRef() == null) {
                    res wholeAgain(this, "Need fCall ref")
                    return Responses OK
                }
                if(fCall getRef() getReturnArgs() isEmpty()) {
                    if(res fatal) {
                        token throwError("Need a multi-return function call as the expression of a tuple-variable declaration!")
                    }
                    res wholeAgain(this, "need multi-return func call")
                    return Responses OK
                }
                parent := trail peek()

                returnArgs := fCall getReturnArgs()
                returnType := fCall getRef() getReturnType() as TypeList
                returnTypes := returnType types

                if(tuple getElements() size() < returnTypes size()) {
                    bad := false
                    if(tuple getElements() isEmpty()) {
                        bad = true
                    } else {
                        element := tuple getElements() last()
                        if(!element instanceOf(VariableAccess)) {
                            element token throwError("Expected a variable access in a tuple-variable declaration!")
                        }
                        if(element as VariableAccess getName() != "_") bad = true
                    }
                    if(bad) tuple token throwError("Tuple variable declaration doesn't match return type %s of function %s" format(returnType toString(), fCall getName()))
                }

                j := 0
                for(element in tuple getElements()) {
                    if(!element instanceOf(VariableAccess)) {
                        element token throwError("Expected a variable access in a tuple-variable declaration!")
                    }
                    argName := element as VariableAccess getName()

                    if(argName == "_") {
                        returnArgs add(null)
                    } else {
                        // woohoo.
                        argType := returnTypes get(j)
                        argDecl := VariableDecl new(argType, argName, element token)
                        returnArgs add(VariableAccess new(argDecl, argDecl token))
                        if(!trail addBeforeInScope(this, argDecl)) {
                            token throwError("Couldn't add %s before %s in scope!" format(argDecl toString(), toString()))
                        }
                    }
                    j += 1
                }
                trail addBeforeInScope(this, fCall)
                parent as Scope remove(this)
            case =>
                token throwError("Unsupported expression type %s for VariableDeclTuple." format(expr class name))
        }

        Responses OK
    }

}

