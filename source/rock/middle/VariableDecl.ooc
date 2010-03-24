import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument, BinaryOp, Cast, Module,
       Block, Scope, FunctionDecl, Argument
import tinker/[Response, Resolver, Trail]
import ../frontend/BuildParams

VariableDecl: class extends Declaration {

    name: String
    fullName: String = null

    type: Type
    expr: Expression
    owner: TypeDecl

    isArg := false
    isGlobal := false
    isConst := false
    isStatic := false
    externName: String = null
    unmangledName: String = null
    
    /** if this VariableDecl is a Func, it can be called! */
    fDecl : FunctionDecl = null

    init: func ~vDecl (.type, .name, .token) {
        this(type, name, null, token)
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

    setOwner: func (=owner) {}

    setExpr: func (=expr) {}
    getExpr: func -> Expression { expr }
    
    isStatic: func -> Bool { isStatic }
    setStatic: func (=isStatic) {}
    
    isConst: func -> Bool { isConst }
    setConst: func (=isConst) {}
    
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

    resolveAccess: func (access: VariableAccess) {
        if(name == access name) {
            access suggest(this)
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        //if(res params veryVerbose) printf("Resolving variable decl %s\n", toString());

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
                
                parent := trail get(idx + 1)
                
                block := Block new(token)
                block getBody() add(this)
                block getBody() add(parent)
                
                result = scope replace(trail get(idx + 1), block)
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

                if(fDecl getReturnType() isGeneric()) {
                    ass := BinaryOp new(VariableAccess new(this, token), realExpr, OpTypes ass, token)
                    if(!trail addAfterInScope(this, ass)) {
                        token throwError("Couldn't add a " + ass toString() + " after a " + toString() + ", trail = " + trail toString())
                    }
                    expr = null
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
        if(getType() instanceOf(FuncType) && fDecl == null) {
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
            if(fType returnType != null) {
                fDecl setReturnType(fType returnType)
            }
            fDecl vDecl = this
        }
        return fDecl
    }

    isMember: func -> Bool { owner != null }

}
