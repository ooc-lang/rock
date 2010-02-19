import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument
import tinker/[Response, Resolver, Trail]

VariableDecl: class extends Declaration {

    name: String
    type: Type
    expr: Expression
    owner: TypeDecl

    isArg := false
    isGlobal := false
    isConst := false
    isStatic := false
    externName: String = null

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
    
    isGlobal: func -> Bool { isGlobal }
    setGlobal: func (=isGlobal) {}
    
    isArg: func -> Bool { isArg }

    getExternName: func -> String { externName }
    setExternName: func (=externName) {}
    isExtern: func -> Bool { externName != null }
    isExternWithName: func -> Bool {
        (externName != null) && !(externName isEmpty())
    }

    resolveAccess: func (access: VariableAccess) {
        if(name == access name) {
            access suggest(this)
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        //printf("Resolving variable decl %s\n", toString());

        if(expr) {
            response := expr resolve(trail, res)
            f(!response ok()) {
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
            f(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        parent := trail peek()
        {
            if(!parent isScope() && !parent instanceOf(TypeDecl)) {
                //println("uh oh the parent of " + toString() + " isn't a scope but a " + parent class name)
                idx := trail findScope()
                result := trail get(idx) addBefore(trail get(idx + 1), this)
                trail peek() replace(this, VariableAccess new(this, token))
                res wholeAgain(this, "parent isn't scope nor typedecl, unwrapped")
                return Responses OK
            }
        }

        if(expr != null && expr instanceOf(FunctionCall)) {
            fCall := expr as FunctionCall
            fDecl := fCall getRef()
            if(!fDecl || !fDecl getReturnType() isResolved()) {
                res wholeAgain(this, "fCall isn't resolved.")
                return Responses OK
            }

            //println("got decl rhs a " + fCall toString())
            if(fDecl getReturnType() isGeneric()) {
                fCall setReturnArg(VariableAccess new(this, token))
                //println("Adding add a " + fCall toString() + " after a " + toString() + ", trail = " + trail toString())
                result := trail addAfterInScope(this, fCall)
                if(!result) {
                    token throwError("Couldn't add a " + fCall toString() + " after a " + toString() + ", trail = " + trail toString())
                }
                expr = null
            }
        }

        if(!isArg && expr == null && type != null && type isGeneric() && type pointerLevel() == 0) {
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

    isMember: func -> Bool { owner != null }

}
