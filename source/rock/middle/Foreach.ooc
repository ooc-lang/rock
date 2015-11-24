import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node,
       VariableAccess, VariableDecl, IntLiteral, Type, RangeLiteral,
       FunctionCall, Block, Scope, While, BinaryOp, BaseType, Tuple
import tinker/[Trail, Resolver, Response, Errors]

Foreach: class extends ControlStatement {

    indexVariable: Expression
    variable: Expression
    collection: Expression

    replaced := false
    _resolved? := false

    init: func ~_foreach (=variable, =collection, .token) {
        super(token)
    }

    isResolved: func -> Bool { _resolved? }

    clone: func -> This {
        copy := new(variable clone(), collection clone(), token)
        body list each(|stat| copy body add(stat clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitForeach(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case variable      => variable      = kiddo; replaced = true; return true
            case indexVariable => indexVariable = kiddo; replaced = true; return true
            case collection    => collection    = kiddo; return true
        }
        return super(oldie, kiddo)
    }

    _createDeclFromAccess: func (vAcc: VariableAccess) {
        varType: Type = null
        if(collection instanceOf?(RangeLiteral)) {
            varType = BaseType new("Int", vAcc token)
        }
        variable = VariableDecl new(varType, vAcc getName(), vAcc token)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (_resolved?) return Response OK

        match variable {
            case vAcc: VariableAccess =>
                if (!replaced) {
                    _createDeclFromAccess(vAcc)
                }
            case tuple: Tuple =>
                if (!replaced) {
                    (a, b) := (tuple[0], tuple[1])
                    match a {
                        case vAcc: VariableAccess =>
                            intType := BaseType new("Int", a token)
                            initialValue := IntLiteral new(-1, vAcc token)
                            indexVariable = VariableDecl new(intType, vAcc getName(), initialValue, a token)
                        case =>
                            res throwError(InvalidForeach new(a token, "Invalid element in foreach tuple, expected identifier"))
                            return Response OK
                    }

                    match b {
                        case vAcc: VariableAccess =>
                            _createDeclFromAccess(vAcc)
                        case =>
                            res throwError(InvalidForeach new(b token, "Invalid element in foreach tuple, expected identifier"))
                            return Response OK
                    }
                }
        }

        trail push(this)

        {
            response := variable resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if (indexVariable) {
            response := indexVariable resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := collection resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        if(!collection instanceOf?(RangeLiteral)) {
            if(collection getType() == null) {
                res wholeAgain(this, "need collection type")
                return Response OK
            }

            // TODO/FIXME: Should 'this' be in the trail when resolving the collection type?
            // This could lead to some weird bugs but is most likely completely irrelevant since a type should not need to use the trail to resolve itself.
            collection getType() resolve(trail, res)

            match (collection getType()) {
                case baseType: BaseType =>
                    // I'm not sure this is the best idea, I don't think we have another way of checking against core types atm though.
                    if (baseType name == "Range") {
                        // If we have a range collection, just go ahead and turn it into a literal node for the backend to generate a C for loop directly.

                        // We will create an access to the range collection and make a range literal with its min and max values.
                        access: VariableAccess
                        match collection {
                            case va: VariableAccess =>
                                // We already have an access, keep that one
                                access = va
                            case =>
                                // We want to avoid side effects, so we create a new declaration and get an access to it.
                                vDecl := VariableDecl new(collection getType(), generateTempName("foreachRangeVar"), collection token)
                                access = VariableAccess new(vDecl, token)

                                if (!trail addBeforeInScope(this, vDecl)) {
                                    res throwError(CouldntAddBeforeInScope new(token, this, vDecl, trail))
                                    return Response OK
                                }
                        }

                        // This is a pretty dirty hack.
                        // We basically mutate the foreache's state to a range literal foreach and force it to be resolved again.
                        // That way, it is not replaced by a while loop + iterator calls but is rather passed to the backend that directly generates a C for loop.

                        // This is our new collection
                        newCol := RangeLiteral new(VariableAccess new(access, "min", collection token),
                                                   VariableAccess new(access, "max", collection token), collection token)

                        // "Reset" our state
                        collection = newCol
                        replaced = false

                        // Rewind to a variable access, let resolve do what it needs to again
                        match variable {
                            case vDecl: VariableDecl =>
                                variable = VariableAccess new(vDecl name, vDecl token)
                        }

                        // Let's go again!
                        res wholeAgain(this, "replaced foreach collection to range literal")
                        return Response OK
                    }
            }

            iterCall := FunctionCall new(collection, "iterator", token)

            response := Response LOOP
            while(response == Response LOOP) {
                response = iterCall resolve(trail, res)
            }

            iterType := iterCall getType()
            if(iterType == null) {
                if(res fatal) res throwError(InternalError new(token, "Couldn't resolve iterType of %s" format(toString())))
                res wholeAgain(this, "need iterType")
                return Response OK
            }
            iterType resolve(trail, res)
            if(!iterType isResolved()) {
                if(res fatal) res throwError(InternalError new(token, "Couldn't resolve iterType %s" format(iterType toString())))
                res wholeAgain(this, "need iterType")
                return Response OK
            }
            //printf("iterCall = %s, ref = %s, iterType name = %s\n", iterCall toString(), iterCall getRef() ? iterCall getRef() toString() : "(nil)", iterType getName())
            //printf("iterType = %s\n", iterType toString())

            list := trail get(trail findScope(), Scope)
            block := Block new(token)

            vdfe := VariableDecl new(iterType, generateTempName("iter"), iterCall, token)
            iterAcc := VariableAccess new(vdfe, token)

            hasNextCall := FunctionCall new(iterAcc, "hasNext__quest", token)
            hasNextCall resolve(trail, res)

            while1 := While new(hasNextCall, token)

            nextCall := FunctionCall new(iterAcc, "next", token)
            nextCall resolve(trail, res)

            if(nextCall getType() == null || !nextCall getType() isResolved()) {
                res wholeAgain(this, "need nextCall type")
                return Response OK
            }

            whileBody := while1 getBody()

            whileBody add(BinaryOp new(variable, nextCall, OpType ass, token))
            if (indexVariable) {
                one := IntLiteral new(1, token)
                whileBody add(BinaryOp new(indexVariable, one, OpType addAss, token))
            }
            whileBody addAll(getBody())

            if(!list replace(this, block)) {
                if(res fatal) {
                    "Failed to replace %s with %s in a %s. trail = %s" printfln(toString(), block toString(), list toString(), trail toString())
                }
                res wholeAgain(this, "Can't turn into a while :/, list = " + list toString() + " (it's a " + list class name)
                return Response LOOP
            }


            block getBody() add(vdfe).
                            add(while1)

            if(variable getType() == null) match variable {
                case vd : VariableDecl   =>
                    vd setType(nextCall getType())
                case acc: VariableAccess =>
                    acc ref as VariableDecl setType(nextCall getType())
            }

            res wholeAgain(this, "Just turned into a while =)")
            return Response OK
        }

        resp := super(trail, res)
        if (!resp ok()) {
            return resp
        }

        _resolved? = true
        return Response OK

    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if(variable instanceOf?(VariableDecl)) {
            vDecl := variable as VariableDecl
            if(vDecl name == access name && access suggest(vDecl)) return 0
        }
        super(access, res, trail)

    }

    toString: func -> String { "for (" + variable toString() + " in " + collection toString() + ")" }

}

InvalidForeach: class extends Error {
    init: super func ~tokenMessage
}
