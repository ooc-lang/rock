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

    init: func ~_foreach (=variable, =collection, .token) {
        super(token)
    }

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
            collection getType() resolve(trail, res)

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

        return super(trail, res)

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
