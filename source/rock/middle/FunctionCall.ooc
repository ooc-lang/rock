import structs/ArrayList
import ../frontend/Token
import Visitor, Expression, FunctionDecl, Argument, Type

FunctionCall: class extends Expression {

    name, suffix = null : String
    args := ArrayList<Expression> new()
    
    ref = null : FunctionDecl
    
    init: func ~funcCall (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }
    
    getScore: func (decl: FunctionDecl) -> Int {
        score := 0
        
        declArgs := decl args
        if(matchesArgs(decl)) {
            score += 10
        } else {
            return 0
        }
        
        if(declArgs size() == 0) return score
        
        declIter : Iterator<Argument> = declArgs iterator()
        if(decl hasThis() && declIter hasNext()) declIter next()
        
        callIter : Iterator<Expression> = args iterator()
        while(callIter hasNext() && declIter hasNext()) {
            declArg := declIter next()
            callArg := callIter next()
            // avoid null types
            if(!declArg type) return -1
            if(declArg type equals(callArg getType())) {
                score += 10
            }
        }
        
        return score
    }
    
    matchesArgs: func (decl: FunctionDecl) -> Bool {
        numArgs := decl args size()
        if(decl hasThis()) numArgs -= 1
        
        if(numArgs == args size() || 
                ((numArgs > 0 && decl args last() instanceOf(VarArg)) &&
                (numArgs - 1 <= args size()))) {
            return true
        }
        return false
    }
    
    getType: func -> Type { ref ? ref returnType : null }
    
    toString: func -> String {
        name +"()"
    }

}
