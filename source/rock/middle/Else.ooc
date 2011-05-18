import ../frontend/Token
import Conditional, Expression, If, Node, Scope, Statement, Visitor
import tinker/[Errors, Resolver, Response, Trail]

Else: class extends Conditional {

    init: func ~_else (.token) { super(null, token) }

    clone: func -> This {
        copy := new(token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitElse(this)
    }

    toString: func -> String {
        "else " + body toString()
    }

    resolve: func(trail: Trail, res: Resolver) -> Response {
        trail push(this)
        scope := trail get(trail findScope()) as Scope
        // Check if an Else has got an If in front of it
        if (scope) {
            self := scope list indexOf(this)
            foundIf := false
            scope list each(|elem| if (elem instanceOf?(If)) {
                    if (scope list indexOf(elem) <= self) {
                        foundIf = true
                    }
                }
            ) 
            if (!foundIf) 
                res throwError(LonesomeElse new(this))

            
        }
        response := body resolve(trail, res)
        trail pop(this)
        return response
        
    }

}

LonesomeElse: class extends Error {

    first: Statement
    init: func (=first) {
        message = first token formatMessage("Found a single-standing `else`. (Note, there must be an if before)", "[ERROR]")
    }
    format: func -> String {
        message
    }

}
