import ../frontend/[Token, BuildParams]
import Visitor, Expression, VariableDecl, Declaration, Type, Node
import tinker/[Resolver, Response, Trail]

ArrayAccess: class extends Expression {

    array, index: Expression
    type: Type = null
    
    getArray: func -> Expression { array }
    getIndex: func -> Expression { index }
    
    init: func ~arrayAccess (=array, =index, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitArrayAccess(this)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(!index resolve(trail, res) ok()) {
            printf("Whole-again because of index!\n")
            res wholeAgain()
        }
        if(!array resolve(trail, res) ok()) {
            printf("Whole-again because of array!\n")
            res wholeAgain()
        }
        
        if(array getType() == null) {
            printf("Whole-again because of array type!\n")
            res wholeAgain()
        } else {
            type = array getType() dereference()
        }
        
        return Responses OK
        
    }
    
    getType: func -> Type {
        return type
    }
    
    toString: func -> String {
        array toString() + "[" + index toString() + "]"
    }
    
    isReferencable: func -> Bool { true }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case array => array = kiddo; true
            case index => index = kiddo; true
            case => false
        }
    }

}
