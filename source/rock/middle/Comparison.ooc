import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl
import tinker/[Resolver, Trail, Response]

include stdint

CompType: cover from Int8 {

    toString: func -> String {
        CompTypes repr get(this)
    }
    
}

CompTypes: class {
    equal = 1,
    notEqual = 2,
    greaterThan = 3,
    smallerThan = 4,
    greaterOrEqual = 5,
    smallerOrEqual = 6 : static const CompType
    
    repr := static ["no-op",
        "==",
        "!=",
        ">",
        "<",
        ">=",
        "<="] as ArrayList<String>
}

Comparison: class extends Expression {

    left, right: Expression
    compType: CompType
    type := static BaseType new("Bool", nullToken)
    
    init: func ~comparison (=left, =right, =compType, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitComparison(this)
    }
    
    getType: func -> Type { type }
    
    toString: func -> String {
        return left toString() + " " + CompTypes repr get(compType) + " " + right toString()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        {
            response := left resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        {
            response := right resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        {
            response := resolveOverload(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
    resolveOverload: func (trail: Trail, res: Resolver) -> Response {
        
        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)
        
        bestScore := 0
        candidate : OperatorDecl = null
        
        reqType := trail peek() getRequiredType()
        
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl, reqType)
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getImports()) {
            module := imp getModule()
            for(opDecl in trail module() getOperators()) {
                score := getScore(opDecl, reqType)
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }
        
        if(candidate != null) {
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)
            fCall getArguments() add(left)
            fCall getArguments() add(right)
            if(!trail peek() replace(this, fCall)) {
                token throwError("Couldn't replace %s with %s!" format(toString(), fCall toString()))
            }
            //return Responses LOOP
            res wholeAgain()
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type) -> Int {
        
        symbol := CompTypes repr[compType]
        
        if(!(op getSymbol() equals(symbol))) {
            return 0 // not the right overload type - skip
        }
        
        //printf("=====\nNot skipped '%s'  vs  '%s'!\n", op getSymbol(), symbol)
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        if(args size() != 2) {
            op token throwError(
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args size()))
        }
        
        score := 0
        
        //printf("Reviewing operator %s for %s\n", op toString(), toString())
        //printf("Left  score = %d (%s vs %s)\n", args get(0) getType() getScore(left  getType()), args get(0) getType() toString(), left getType() toString())
        //printf("Right score = %d (%s vs %s)\n", args get(1) getType() getScore(right getType()), args get(1) getType() toString(), right getType() toString())
        
        score += args get(0) getType() getScore(left getType())
        score += args get(1) getType() getScore(right getType())        
        if(reqType) {
            score += fDecl getReturnType() getScore(reqType)
        }
        
        //printf("Final score = %d\n", score)
        
        return score
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left => left = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

}
