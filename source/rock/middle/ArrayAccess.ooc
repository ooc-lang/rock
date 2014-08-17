import structs/ArrayList
import ../frontend/[Token, BuildParams]
import Visitor, Expression, VariableDecl, Declaration, Type, Node, Parenthesis,
       OperatorDecl, FunctionCall, Import, Module, BinaryOp, EnumDecl,
       VariableAccess, AddressOf, ArrayCreation, TypeDecl, Argument, Scope
import tinker/[Resolver, Response, Trail, Errors]

ArrayAccess: class extends Expression {

    array: Expression
    indices := ArrayList<Expression> new()

    type: Type = null

    getArray: func -> Expression { array }
    setArray: func (=array) {}

    init: func ~arrayAccess (=array, .token) {
        super(token)
    }

    clone: func -> This {
        copy := new(array clone(), token)
        indices each(|e| copy indices add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitArrayAccess(this)
    }

    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { false }

    getGenericOperand: func -> Expression {
        if(getType() isGeneric() && getType() pointerLevel() == 0) {
            typeAcc := VariableAccess new(getType() getName(), token)
            sizeAcc := VariableAccess new(typeAcc, "size", token)
            arrAcc := ArrayAccess new(array, token)
            for(index in indices) {
                // FIXME: that's fucked up if we have more than one index anyway
                arrAcc indices add(BinaryOp new(Parenthesis new(index, arrAcc token), sizeAcc, OpType mul, arrAcc token))
            }
            return AddressOf new(arrAcc, arrAcc token)
        }
        return super()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(res fatal && type == null) {
            if (!array isResolved()) {
                // try to let the inner expression throw an error
                array resolve(trail, res)

                res wholeAgain(this, "Reference to undeclared variable.")
                return Response OK
            }
            res throwError(InvalidArrayAccess new(token, "Trying to index something that isn't an array, nor has an overload for the []/[]= operators"))
        }

        trail push(this)

        for(index in indices) {
            if(!index resolve(trail, res) ok()) {
                res wholeAgain(this, "because of index!")
            }
        }
        if(!array resolve(trail, res) ok()) {
            res wholeAgain(this, "because of array!")
        }

        trail pop(this)

        if(!handleArrayCreation(trail, res) ok()) {
            return Response LOOP
        }

        {
            hasOverload := true
            response := resolveOverload(trail, res, hasOverload&)
            if(!response ok()) {
                res wholeAgain(this, "overload says some things aren't resolved yet")
                return Response OK
            }

            if(!hasOverload) {
                // If we do not find an overload, we must make sure the indices are valid (numeric or enum members) for raw arrays (C and ooc arrays)
                for(index in indices) {
                    if(!isValidIndex(index)) {
                        if (res fatal) {
                            res throwError(InvalidArrayIndex new(token, "Trying to access an array with an index of non numeric type %s without proper overload" format(index getType() ? index getType() toString() : "(nil)")))
                        } else {
                            // try again later o/
                            res wholeAgain(this, "need to figure out if something is a valid index or not")
                            return Response OK
                        }
                    }
                }
            }
        }

        if(array getType() == null) {
            res wholeAgain(this, "because of array type!")
        } else {
            type = array getType() dereference()
            if(type == null) {
                res wholeAgain(this, "because of array dereference type!")
            }
        }

        return Response OK

    }

    isValidIndex: func(index: Expression, ignore := false) -> Bool {
        if(!ignore) {
            deepDown := this as Expression
            while(deepDown instanceOf?(ArrayAccess)) {
                deepDown = deepDown as ArrayAccess array
            }

            deepType := deepDown getType()
            if (!deepType) {
                // not resolved yet, will need to check again on next round
                return false
            }
            if(deepDown getType() pointerLevel() <= 0 && !deepDown getType() instanceOf?(ArrayType)) {
                // If we are not dealing with an ooc array or a pointer and we care
                // about type checking, we just return true because a non
                // overloaded access on such a type will be detected elsewhere
                return true
            }
        }

        // Just check whether the index is of a numeric type or of an enum type that gets translated to an integer in C anyway
        index getType() isNumericType() || (index getType() getRef() ? index getType() getRef() instanceOf?(EnumDecl) : false)
    }

    handleArrayCreation: func (trail: Trail, res: Resolver) -> Response {

        deepDown := this as Expression
        while(deepDown instanceOf?(ArrayAccess)) {
            deepDown = deepDown as ArrayAccess array
        }

        if(deepDown instanceOf?(VariableAccess) && deepDown as VariableAccess getRef() instanceOf?(TypeDecl)) {
            if(indices getSize() > 1) {
                res throwError(InvalidArrayCreation new(token, "You can't call new on an ArrayAccess with several indices! Only one index is supported."))
            }

            index := indices[0]
            if (!index getType() || !index getType() getRef()) {
                res wholeAgain(this, "need index type turned into ArrayCreation!")
                return Response OK
            }

            // We should only pass numbers when creating an array
            // We don't care about checking whether the type is an array/pointer in this case, as we know we are accessing a class.
            if(!isValidIndex(index, true)) {
                if (!res fatal) {
                    res wholeAgain(this, "need to check index type")
                    return Response OK
                }

                typeString := index getType() ? index getType() toString() : "(nil)"
                message := "Trying to create an array with a size of non numeric type %s" format(typeString)
                err := InvalidArrayIndex new(token, message)
                res throwError(err)
            }

            varAcc := deepDown as VariableAccess
            tDecl := varAcc getRef() as TypeDecl
            innerType := tDecl getInstanceType()

            parent := trail peek()
            if(parent instanceOf?(Scope)) {
                parent = (parent as Scope getSize() == 1) ? parent as Scope first() : parent
            }

            if(!parent instanceOf?(FunctionCall)) {
                if(parent instanceOf?(ArrayAccess)) {
                    // will be taken care of later
                    return Response OK
                }
                res throwError(InvalidArrayCreation new(token, "Unexpected ArrayAccess to a type, parent is a %s, ie. %s" format(parent class name, parent toString())))
            }

            fCall := parent as FunctionCall
            if(fCall getName() != "new") {
                res throwError(InvalidArrayCreation new(token, "Good lord, what are you trying to call on that array type?"))
            }

            grandpa := trail peek(2)

            arrayType := ArrayType new(innerType, index, token)

            deepDown = array
            while(deepDown instanceOf?(ArrayAccess)) {
                arrAcc := deepDown as ArrayAccess
                if(arrAcc indices getSize() > 1) {
                    res throwError(InvalidArrayCreation new(token, "You can't call new on an ArrayAccess with several indices! Only one index is supported."))
                }
                arrayType = ArrayType new(arrayType, arrAcc indices[0], token)
                deepDown = deepDown as ArrayAccess array
            }
            arrayCreation := ArrayCreation new(arrayType, token)

            // TODO: this is all very hackish. More checking is needed
            if(grandpa instanceOf?(VariableDecl)) {
                vDecl := grandpa as VariableDecl
                vAcc := VariableAccess new(vDecl, token)
                if(vDecl isMember()) {
                    if(vDecl isStatic()) {
                        vAcc expr = VariableAccess new(vDecl getOwner() getInstanceType(), token)
                    } else {
                        vAcc expr = VariableAccess new("this", token)
                    }
                }
                arrayCreation expr = vAcc
            } else if(grandpa instanceOf?(BinaryOp)) {
                arrayCreation expr = grandpa as BinaryOp getLeft()
            }
            grandpa replace(fCall, arrayCreation)

            // used to be a LOOP
            res wholeAgain(this, "ArrayAccess turned into ArrayCreation!")
            return Response OK
        }

        return Response OK

    }

    resolveOverload: func (trail: Trail, res: Resolver, hasOne?: Bool* = null) -> Response {

        /*
        "Looking for an overload of %s[%s], %s" printfln(
            array getType() ? array getType() toString() : "(nil)",
            indices[0] getType() ? indices[0] getType() toString() : "(nil)",
            array getType() && array getType() getRef() ? array getType() getRef() toString() : "(nil)"
        )
        */

        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)

        bestScore := 0
        candidate : OperatorDecl = null

        parent := trail peek()

        inAssign := (parent instanceOf?(BinaryOp)) &&
                    (parent as BinaryOp isAssign()) &&
                    (parent as BinaryOp getLeft() == this)

        // first we check the lhs's type
        lhsType := array getType()

        if (lhsType) {
            lhsTypeRef := lhsType getRef()

            match lhsTypeRef {
                case tDecl: TypeDecl =>
                    if (tDecl isMeta) {
                        tDecl = tDecl getNonMeta()
                    }

                    for (opDecl in tDecl operators) {
                        //"Matching %s against %s" printfln(opDecl toString(), toString())
                        score := getScore(opDecl, inAssign ? parent as BinaryOp : null, res)
                        if(score == -1) {
                            return Response LOOP
                        }
                        if(score > bestScore) {
                            bestScore = score
                            candidate = opDecl
                        }
                    }
            }
        }

        // then we check the current module
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl, inAssign ? parent as BinaryOp : null, res)
            if(score == -1) {
                return Response LOOP
            }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }

        // and then the imports
        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl, inAssign ? parent as BinaryOp : null, res)
                if(score == -1) return Response LOOP
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }

        if(candidate != null) {
            if(hasOne?) hasOne?@ = true

            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)

            if (fDecl owner) {
                fCall expr = array
            } else {
                fCall getArguments() add(array)
            }

            fCall getArguments() addAll(indices)

            if(inAssign) {
                assign := parent as BinaryOp
                fCall getArguments() add(assign getRight())

                if(!trail peek(2) replace(assign, fCall)) {
                    res throwError(CouldntReplace new(token, assign, fCall, trail))
                }
            } else {
                if(!trail peek() replace(this, fCall)) {
                    res throwError(CouldntReplace new(token, this, fCall, trail))
                }
            }

            res wholeAgain(this, "Just been replaced with an overload")
            return Response LOOP
        }
        if(hasOne?) hasOne?@ = false

        return Response OK

    }

    isResolved: func -> Bool { array isResolved() && type != null }
    getScore: func (op: OperatorDecl, assign: BinaryOp, res: Resolver) -> Int {
        if(!(op getSymbol() equals?(assign != null ? "[]=" : "[]"))) {
            return 0 // not the right overload type - skip
        }
        diff := op getSymbol() endsWith?("=") ? 2 : 1
        requiredArgs := indices getSize() + diff

        fDecl := op getFunctionDecl()
        args := ArrayList<VariableDecl> new()
        args addAll(fDecl getArguments())

        if (fDecl owner) {
            args add(0, fDecl owner getThisDecl())
        }

        if(!args last() instanceOf?(VarArg) && (args getSize() != requiredArgs)) {
            // not a match!
            if(res params veryVerbose) {
                "For %s vs %s, got %d args, %d indices, diff is %d - no luck!" format(op toString(), toString(), args getSize(), indices getSize(), diff) println()
            }
            return 0
        }

        // Handle the array expression first, e.g. array[indices...]
        opArray := args get(0)
        if(opArray getType() == null || array getType() == null) {
            return -1
        }

        arrayScore := array getType() getScore(opArray getType())
        if(arrayScore == -1) {
            return -1
        }

        indexScore := 0
        for(i in 0..(args getSize() - diff)) {
            opIndex := args[i + 1]
            index := indices[i]
            //"opIndex = %s, index = %s (diff = %d)" printfln(opIndex toString(), index toString(), diff)
            match {
                case opIndex instanceOf?(VarArg) =>
                    indexScore += Type SCORE_SEED
                case opIndex getType() == null =>
                    return -1
                case index   getType() == null =>
                    return -1
                case =>
                    indexScore += index getType() getScore(opIndex getType())
                    //"indexScore = %d, %s vs %s" printfln(indexScore, index getType() toString(), opIndex getType() toString())
            }
        }

        if(assign != null) {
            rightType := assign getRight() getType()
            assignScore := rightType ? rightType getScore(args last() getType()) : 0
            if(assignScore == -1) return -1
            indexScore += assignScore
        }

        //"Score of %s for %s = %d (array %d, index %d)" printfln(op toString(), toString(), arrayScore + indexScore, arrayScore, indexScore)

        return arrayScore + indexScore

    }

    getType: func -> Type {
        type
    }

    toString: func -> String {
        b := Buffer new()
        b append(array toString()). append('[')
        isFirst := true
        for(index in indices) {
            if(isFirst) isFirst = false
            else        b append(", ")
            b append(index toString())
        }
        b append(']')
        b toString()
    }

    isReferencable: func -> Bool { true }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case array => array = kiddo; true
            case => indices replace(oldie as Expression, kiddo as Expression)
        }
    }

}

InvalidArrayAccess: class extends Error {
    init: super func ~tokenMessage
}

InvalidArrayCreation: class extends Error {
    init: super func ~tokenMessage
}

InvalidArrayIndex: class extends Error {
    init: super func ~tokenMessage
}

