import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       IntLiteral, Ternary
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
    smallerOrEqual = 6,
    compare = 7 : static const CompType
    
    repr := static ["no-op",
        "==",
        "!=",
        ">",
        "<",
        ">=",
        "<=",
        "<=>"] as ArrayList<String>
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
    
    getType: func -> Type { This type }
    
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
        {
            response := This type resolve(trail, res)
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
            if(score == -1) { res wholeAgain(this, "score of %s == -1 !!" format(opDecl toString())); return Responses OK }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl, reqType)
                if(score == -1) { res wholeAgain(this, "score of %s == -1 !!" format(opDecl toString())); return Responses OK }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }
        
        if(candidate == null) {
            
            if(compType == CompTypes compare) {
                // a <=> b
                // a > b ? 1 : (a < b ? -1 : 0)
                
                minus := IntLiteral new(-1, token)
                zero  := IntLiteral new(0,  token)
                plus  := IntLiteral new(1,  token)
                inner := Ternary new(Comparison new(left, right, CompTypes smallerThan,  token), minus, zero,  token)
                outer := Ternary new(Comparison new(left, right, CompTypes greaterThan, token),  plus,  inner, token)
                
                if(!trail peek() replace(this, outer)) {
                    token throwError("Couldn't replace %s with %s!" format(toString(), outer toString()))
                }
            }
            
        } else {
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)
            fCall getArguments() add(left)
            fCall getArguments() add(right)
            node := fCall as Node
            
            if(candidate getSymbol() equals("<=>")) {
                node = Comparison new(node, IntLiteral new(0, token), compType, token)
            }
            
            if(!trail peek() replace(this, node)) {
                if(res fatal) token throwError("Couldn't replace %s with %s!" format(toString(), node toString()))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Responses OK
                //return Responses LOOP
            }
            res wholeAgain(this, "Just replaced with an operator overloading")
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type) -> Int {
        
        symbol := CompTypes repr[compType]
        
        half := false
        
        if(!(op getSymbol() equals(symbol))) {
            if(op getSymbol() equals("<=>")) half = true
            else return 0 // not the right overload type - skip
        }
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        if(args size() != 2) {
            op token throwError(
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args size()))
        }
        
        score := 0
        
        opLeft  := args get(0)
        opRight := args get(1)
        
        if(opLeft getType() == null || opRight getType() == null || left getType() == null || right getType() == null) {
            return -1
        }
        
        score += opLeft  getType() getScore(left getType())
        score += opRight getType() getScore(right getType())
        if(reqType) {
            score += fDecl getReturnType() getScore(reqType)
        }
        
        if(half) score /= 2  // used to prioritize '<=', '>=', and blah, over '<=>'
        
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
