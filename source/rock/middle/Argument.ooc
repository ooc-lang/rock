import ../frontend/Token
import VariableDecl, Type, Visitor, Node, TypeDecl, VariableAccess, BinaryOp,
       FunctionDecl
import tinker/[Trail, Resolver, Response]

/**
   A function argument.

   Read FunctionDecl for more infos on the different types of arguments.

   :author: Amos Wenger (nddrylliog)
 */
Argument: abstract class extends VariableDecl {

    init: func ~argument (.type, .name, .token) { super(type, name, token) }

    toString: func -> String { name empty?() ? type toString() : super() }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(type == null) {
            res wholeAgain(this, "null type")
            return Responses OK
        }

        if(!type isResolved() || type getRef() == null) {
            response := type resolve(trail, res)
            if(!response ok()) {
                return response
            }
            if(!type isResolved() || type getRef() == null) res wholeAgain(this, "Hasn't resolved type yet!")
        }

        return Responses OK

    }

}

VarArg: class extends Argument {

    init: func ~varArg (.token) { super(null, "<...>", token) }

    accept: func (visitor: Visitor) {
        visitor visitVarArg(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    isResolved: func -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        return Responses OK

    }

    toString: func -> String { "..." }

}

DotArg: class extends Argument {

    ref: VariableDecl = null

    init: func ~dotArg (.name, .token) { super(null, name, token) }

    isResolved: func -> Bool { type != null }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        idx := trail find(TypeDecl)
        if(idx == -1) token throwError("Use of a %s outside a type declaration! That's nonsensical." format(class name))

        tDecl := trail get(idx, TypeDecl)
        ref = tDecl getVariable(name)
        if(ref == null) {
            if(res fatal) token throwError("%s refers to non-existing member variable '%s' in type '%s'" format(class name, name, tDecl getName()))
            res wholeAgain(this, "DotArg wants its variable!")
            return Responses OK
        }

        type = ref getType()
        if(type == null) {
            if(res fatal) {
                token throwError("Couldn't resolve %s referring to '%s' in type '%s'" format(class name, name, tDecl getName()))
            }
            res wholeAgain(this, "Hasn't resolved type yet :x")
            return Responses OK
        }

        return super(trail, res)

    }

    toString: func -> String { "." + name }

}

AssArg: class extends DotArg {

    unwrapped := false

    init: func ~assArg (.name, .token) { super(name, token) }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        super(trail, res)

        if(unwrapped) return Responses OK

        if(ref == null) {
            res wholeAgain(this, "Yet has to be unwrapped =)")
        } else {
            fDecl := trail get(trail find(FunctionDecl), FunctionDecl)
	    	//printf("Unwrapping AssArg %s in function %s\n", toString(), fDecl toString())
            if(fDecl getName() != "new") {
                fDecl getBody() add(0, BinaryOp new(
                    VariableAccess new(VariableAccess new("this", token), name, token),
                    VariableAccess new(this as VariableDecl, token),
                    OpType ass,
                    token
                ))
                unwrapped = true
	            res wholeAgain(this, "Just unwrapped!")
            }
        }

        return Responses OK

    }

    toString: func -> String { "=" + name }

}
