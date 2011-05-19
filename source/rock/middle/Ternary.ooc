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

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        {
            response := condition resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := ifTrue resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := ifFalse resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        
        parent := trail peek()
            
        if(ifTrue getType() == null || ifFalse getType() == null) {
            res wholeAgain(this, "Need ifTrue/ifFalse types")
            return Response OK
        }
        
        if(!ifTrue getType() equals?(ifFalse getType())) {
            isLeftPointerLike  := ifTrue  getType() getGroundType() pointerLevel() > 0 || ifTrue  getType() getGroundType() getRef() instanceOf?(ClassDecl)
            isRightPointerLike := ifFalse getType() getGroundType() pointerLevel() > 0 || ifFalse getType() getGroundType() getRef() instanceOf?(ClassDecl)
            compatible := !(isLeftPointerLike ^ isRightPointerLike)
            
            if(!compatible) {
                res throwError(DifferentTernaryTypes new(token, "Using different types in a ternary expression is forbidden. Find another way :)"))
            }
        }

        return Response OK

    }

    toString: func -> String { condition toString() + " ? " + ifTrue toString() + " : " + ifFalse toString() }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case condition => condition = kiddo; true
            case ifTrue    => ifTrue = kiddo; true
            case ifFalse   => ifFalse = kiddo; true
            case => false
        }
    }

}

DifferentTernaryTypes: class extends Error {
    init: super func ~tokenMessage
}
