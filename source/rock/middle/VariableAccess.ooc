import ../frontend/[Token, BuildParams, AstBuilder], io/File
import BinaryOp, Visitor, Expression, VariableDecl, FunctionDecl,
       TypeDecl, Declaration, Type, Node, ClassDecl, NamespaceDecl,
       EnumDecl, PropertyDecl, FunctionCall, Module, Import, FuncType,
       NullLiteral, AddressOf, BaseType, StructLiteral, Return,
       Argument, InlineContext, Scope

import tinker/[Resolver, Response, Trail, Errors]
import structs/ArrayList

VariableAccess: class extends Expression {

    _warned := false    
    _staticFunc : FunctionDecl = null
    
    expr: Expression {
        get
        set (newExpr) {
            expr = newExpr
            match newExpr {
                case acc: VariableAccess => acc reverseExpr = this
            }
        }
    }
    
    reverseExpr: VariableAccess
    
    name: String

    ref: Declaration

    init: func ~variableAccess (.name, .token) {
        init(null, name, token)
    }

    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
    }

    init: func ~varDecl (varDecl: VariableDecl, .token) {
        super(token)
        name = varDecl getName()
        ref = varDecl
    }

    clone: func -> This {
        new(expr ? expr clone() : null, name, token)
    }

    init: func ~typeAccess (type: Type, .token) {
        super(token)
        name = type getName()
        if(type getRef() instanceOf?(VariableDecl)) {
            varDecl := type getRef() as VariableDecl
            if(varDecl getOwner() != null) {
                if(varDecl isStatic) {
                    expr = VariableAccess new(varDecl getOwner() getInstanceType(), token)
                } else {
                    expr = VariableAccess new("this", token)
                }
            }
        } else {
            // else, it's safe to carry the ref
            ref = type getRef()
        }
    }

    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }

    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { false }

    debugCondition: inline func -> Bool {
        false
    }

    suggest: func (node: Node) -> Bool {
        match node {
            case candidate: VariableDecl =>
                // if we're accessing a member, we're expecting the
                // candidate to belong to a TypeDecl..
                if(isMember() && !candidate isMember()) {
                    return false
                }

                if(_staticFunc && candidate isMember() && candidate == candidate owner thisDecl) {
                    //token formatMessage("Got thisDecl of " + candidate owner toString() + " in static func " + _staticFunc toString(), "INFO") println()

                    // Can't access an instance variable from static function
                    return false
                }

                ref = candidate
                if(isMember() && candidate owner isMeta) {
                    expr = VariableAccess new(candidate owner getNonMeta() getInstanceType(), candidate token)
                }

                true
            case candidate: FunctionDecl =>
                // if we're accessing a member, we're expecting the candidate
                // to belong to a TypeDecl..
                if((expr != null) && (candidate owner == null)) {
                    return false
                }

                ref = candidate
                true
            case tDecl: TypeDecl =>
                // TODO: the use of 'val' here is a workaround - an if/else should
                // be an expression.
                val := true
                if(tDecl isAddon()) {
                    // First rule of resolve club is: you do not resolve to an addon.
                    // Always resolve to the base instead.
                    val = suggest(tDecl getBase() getNonMeta())
                } else {
                    ref = node
                }
                val
            case nDecl: NamespaceDecl =>
                ref = node
                true
            case =>
                false
        }
    }

    isResolved: func -> Bool { ref != null && getType() != null }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(debugCondition()) {
            "%s is of type %s" printfln(name toCString(), getType() ? getType() toString() toCString() : "(nil)" toCString())
        }

        trail onOuter(FunctionDecl, |fDecl|
            if(fDecl isStatic()) _staticFunc = fDecl
        )

        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) return response
            //printf("Resolved expr, type = %s\n", expr getType() ? expr getType() toString() : "(nil)")
        }

        if(expr && name == "class") {
            if(expr getType() == null || expr getType() getRef() == null) {
                res wholeAgain(this, "expr type or expr type ref is null")
                return Response OK
            }
            if(!expr getType() getRef() instanceOf?(ClassDecl)) {
                name = expr getType() getName()
                ref = expr getType() getRef()
                expr = null
            }
        }

        /*
         * Try to resolve the access from the expr
         */
        if(!ref && expr) {
            if(expr instanceOf?(VariableAccess) && expr as VariableAccess getRef() != null \
              && expr as VariableAccess getRef() instanceOf?(NamespaceDecl)) {
                expr as VariableAccess getRef() resolveAccess(this, res, trail)
            } else {
                exprType := expr getType()
                if(exprType == null) {
                    res wholeAgain(this, "expr's type isn't resolved yet, and it's needed to resolve the access")
                    return Response OK
                }
                //printf("Null ref and non-null expr (%s), looking in type %s\n", expr toString(), exprType toString())
                typeDecl := exprType getRef()
                if(!typeDecl) {
                    if(res fatal) res throwError(UnresolvedType new(expr token, expr getType(), "Can't resolve type %s" format(expr getType() toString() toCString())))
                    res wholeAgain(this, "unresolved access, looping")
                    return Response OK
                }
                typeDecl resolveAccess(this, res, trail)
            }
        }

        /*
         * Try to resolve the access from the trail
         *
         * It's far simpler than resolving a function call, we just
         * explore the trail from top to bottom and retain the first match.
         */
        if(!ref && !expr) {
            depth := trail getSize() - 1
            while(depth >= 0) {
                node := trail get(depth)
                if(node instanceOf?(TypeDecl)) {
                    tDecl := node as TypeDecl
                    if(tDecl isMeta) node = tDecl getNonMeta()

                    // in initialization of a member object!
                    if(!ref && name == "this" && trail find(Scope) == -1) {
                        suggest(node as TypeDecl thisDecl)
                    }
                }
                node resolveAccess(this, res, trail)

                if(ref) {
                    if(expr) {
                        if(expr instanceOf?(VariableAccess)) {
                            trail push(this)
                            response := expr resolve(trail, res)
                            trail pop(this)
                            if(!response ok()) return Response LOOP
                            varAcc := expr as VariableAccess
                        }
                    }

                    // only accesses to variable decls need to be partialed (not type decls)
                    if(ref instanceOf?(VariableDecl) && !ref as VariableDecl isGlobal() && expr == null) {
                        closureIndex := trail find(FunctionDecl)

                        if(closureIndex > depth) { // if it's not found (-1), this will be false anyway
                            closure := trail get(closureIndex, FunctionDecl)
                            mode := "v"
                            if(closure isAnon()) {
                                bOpIDX := trail find(BinaryOp)
                                if (trail find(BinaryOp) != -1) {
                                    bOp: BinaryOp = trail get(bOpIDX)
                                    if (bOp getLeft() == this && bOp isAssign()) mode = "r"
                                }
                                closure markForPartialing(ref as VariableDecl, mode)
                                closure clsAccesses add(this)
                            }
                        }
                    }

                    break // break on first match
                }
                depth -= 1
            }
        }

        if (getType() instanceOf?(FuncType) ) {
            fType := getType() as FuncType
            parent := trail peek()

            if (!fType isClosure) {
                closureElements := [
                    this
                    NullLiteral new(token)
                ] as ArrayList<VariableAccess>

                closureType: FuncType = null

                if (parent instanceOf?(FunctionCall)) {
                    /*
                     * The case we're looking for is this one:
                     *
                     *     registerCallback(exit)
                     *
                     * If registerCallback is an ooc function and the arg is
                     * a FuncType we need to make a StructLiteral out of ourselves.
                     */
                    fCall := parent as FunctionCall
                    ourIndex := fCall args indexOf(this)
                    fDecl := fCall getRef()
                    if(!fDecl) {
                        res wholeAgain(this, "need ref!")
                        return Response OK
                    }
                    // 1.) extern C functions don't accept a Closure_struct
                    // 2.) If ref is not a FDecl, it's probably already "closured" and doesn't need to be wrapped a second time
                    if (!fDecl isExtern() && ref instanceOf?(FunctionDecl))
                        closureType = fDecl args get(ourIndex) getType()

                } elseif (parent instanceOf?(BinaryOp)) {
                    binOp := parent as BinaryOp
                    if(binOp isAssign() && binOp getRight() == this) {
                        if(binOp getLeft() getType() == null) {
                            res wholeAgain(this, "need type of BinOp's lhs")
                            return Response OK
                        }
                        closureType = binOp getLeft() getType() clone()
                    }
                } elseif (parent instanceOf?(Return)) {
                    fIndex := trail find(FunctionDecl)
                    if (fIndex != -1) {
                        closureType = trail get(fIndex, FunctionDecl) returnType clone()
                    }
                }

                if (closureType && closureType instanceOf?(FuncType)) {
                    fType isClosure = true
                    closure := StructLiteral new(closureType, closureElements, token)
                    if(!trail peek() replace(this, closure)) {
                        res throwError(CouldntReplace new(token, this, closure, trail))
                    }
                }
            }
        }

        // Simple property access? Replace myself with a getter call.
        if(ref && ref instanceOf?(PropertyDecl)) {
            // Make sure we're not in a getter/setter yet (the trail would
            // contain `ref` then)
            if(ref as PropertyDecl inOuterSpace(trail)) {
                // Test that we're not part of an assignment (which will be replaced by a setter call)
                // That's also the case for operators like +=, *=, /= ...
                // TODO: This should be nicer.
                if(!(trail peek() instanceOf?(BinaryOp) && trail peek() as BinaryOp isAssign())) {
                    property := ref as PropertyDecl
                    fCall := FunctionCall new(expr, property getGetterName(), token)
                    trail peek() replace(this, fCall)
                    return Response OK
                }
            } else {
                // We are in a setter/getter and we're having a variable access. That means
                // the property is not virtual.
                ref as PropertyDecl setVirtual(false)
            }
        }

        if(!_warned && trail peek() instanceOf?(Scope)) {
            parent := trail peek() as Scope

            size := parent list getSize()
            idxOf := parent list indexOf(this)
            if(idxOf != -1 && idxOf != (size - 1)) {
                res throwError(Warning new(token, "Statement with no effect"))
            }
            _warned = true
        }

        if(!ref) {
            if(res fatal) {
                subject := this
                if(reverseExpr && _staticFunc && name == "this") {
                    res throwError(InvalidAccess new(this,
                        "Can't access instance variable '%s' from static function '%s'!" format(reverseExpr getName() toCString(), _staticFunc getName() toCString())
                    ))
                }
                
                if(res params veryVerbose) {
                    println("trail = " + trail toString())
                }
                msg := "Undefined symbol '%s'" format(subject toString() toCString())
                if(res params helpful) {
                    similar := subject findSimilar(res)
                    if(similar) {
                        msg += similar
                    }
                }
                res throwError(UnresolvedAccess new(subject, msg))
            }
            if(res params veryVerbose) {
                printf("     - access to %s%s still not resolved, looping (ref = %s)\n", \
                expr ? (expr toString() + "->")  toCString() : "" toCString(), name toCString(), ref ? ref toString() toCString() : "(nil)" toCString())
            }
            res wholeAgain(this, "Couldn't resolve varacc")
        }

        return Response OK

    }

    findSimilar: func (res: Resolver) -> String {

        buff := Buffer new()

        for(imp in res collectAllImports()) {
            module := imp getModule()

            type := module getTypes() get(name)
            if(type) {
                buff append(" (Hint: there's such a type in "). append(imp getPath()). append(")")
            }
        }

        buff toString()

    }

    getRef: func -> Declaration { ref }

    getType: func -> Type {

        if(!ref) return null
        if(ref instanceOf?(Expression)) {
            return ref as Expression getType()
        }
        return null
    }

    isMember: func -> Bool {
        (expr != null) &&
        !(expr instanceOf?(VariableAccess) &&
          expr as VariableAccess getRef() != null &&
          expr as VariableAccess getRef() instanceOf?(NamespaceDecl)
        )
    }

    getName: func -> String { name }

    toString: func -> String {
        expr ? (expr toString() + " " + name) : name
    }

    isReferencable: func -> Bool { true }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo as Expression; true
            case => false
        }
    }

    setRef: func(=ref) {}

}

UnresolvedAccess: class extends Error {
    access: VariableAccess

    init: func (=access, .message) {
        super(access token, message)
    }
}

InvalidAccess: class extends Error {
    access: VariableAccess

    init: func (=access, .message) {
        super(access token, message)
    }
}



