import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, FunctionDecl, ClassDecl
import tinker/[Response, Resolver, Trail, Errors]

Ternary: class extends Expression {

    /*
     * TODO: We must check if 'ifTrue' and 'ifFalse' have compatible types,
     * and cast one of them if needed
     */
    condition, ifTrue, ifFalse : Expression

    init: func ~ternary (=condition, =ifTrue, =ifFalse, .token) {
        super(token)
    }

    clone: func -> This {
        new(condition clone(), ifTrue clone(), ifFalse clone(), token)
    }

    getType: func -> Type {
        // hmm it would probably be good to check that ifTrue and ifFalse have compatible types
        ifTrue getType()
    }

    accept: func (visitor: Visitor) {
        visitor visitTernary(this)
    }

    hasSideEffects : func -> Bool { condition hasSideEffects() || ifTrue hasSideEffects() || ifFalse hasSideEffects() }

    _resolved := false

    resolve: func (trail: Trail, res: Resolver) -> Response {

        match (resolveInsides(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        if(!ifTrue getType() equals?(ifFalse getType())) {
            isLeftPointerLike  := ifTrue  getType() getGroundType() pointerLevel() > 0 || ifTrue  getType() getGroundType() getRef() instanceOf?(ClassDecl)
            isRightPointerLike := ifFalse getType() getGroundType() pointerLevel() > 0 || ifFalse getType() getGroundType() getRef() instanceOf?(ClassDecl)
            compatible := !(isLeftPointerLike ^ isRightPointerLike)
            
            if(!compatible) {
                res throwError(DifferentTernaryTypes new(token, "Using different types in a ternary expression is forbidden. Find another way :)"))
            }
        }

        _resolved = true

        return Response OK

    }

    isResolved: func -> Bool {
        _resolved && ifTrue isResolved() && ifFalse isResolved()
    }

    refresh: func {
        _resolved = false
    }

    resolveInsides: func (trail: Trail, res: Resolver) -> BranchResult {
        trail push(this)

        hasUnresolved := false

        match (condition resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        if (!condition isResolved() || condition getType() == null) {
            hasUnresolved = true
        }

        match (ifTrue resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        if (!ifTrue isResolved() || ifTrue getType() == null) {
            hasUnresolved = true
        }

        match (ifFalse resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        if (!ifFalse isResolved() || ifFalse getType() == null) {
            hasUnresolved = true
        }

        trail pop(this)

        if (hasUnresolved) {
            res wholeAgain(this, "need all insides of ternary to be resolved")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    toString: func -> String { condition toString() + " ? " + ifTrue toString() + " : " + ifFalse toString() }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case condition =>
                condition = kiddo
                refresh()
                true
            case ifTrue =>
                ifTrue = kiddo
                refresh()
                true
            case ifFalse =>
                ifFalse = kiddo
                refresh()
                true
            case => false
        }
    }

}

DifferentTernaryTypes: class extends Error {
    init: super func ~tokenMessage
}
