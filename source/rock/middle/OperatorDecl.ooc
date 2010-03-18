import text/Buffer
import ../frontend/Token
import FunctionDecl, Expression, Type, Visitor, Node, Argument
import tinker/[Resolver, Response, Trail]

OperatorDecl: class extends Expression {

    symbol : String
    fDecl = null : FunctionDecl

    init: func ~opDecl (=symbol, .token) {
        super(token)
    }
    
    setFunctionDecl: func (=fDecl) {}
    getFunctionDecl: func -> FunctionDecl { fDecl }
    
    getSymbol: func -> String { symbol }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(fDecl) }

    getType: func -> Type { fDecl getType() }
    
    toString: func -> String {
        "operator " + symbol + (fDecl ? fDecl getArgsRepr() : "")
    }
    
    isResolved: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(fDecl getName() isEmpty()) {
            sb := Buffer new()
            sb append("__OP_"). append(getName())
            
            for(arg in fDecl args) {
                sb append("_"). append(arg getType() toMangledString())
            }
            
            if(!fDecl isVoid()) {
                sb append("__"). append(fDecl getReturnType() toMangledString())
            }
            
            fDecl setName(sb toString())
        }
        
        fDecl resolve(trail, res)
            
    }
    
    getName: func -> String {
        return match (symbol) {
            case "[]"  =>  "IDX"
            case "+"   =>  "ADD"
            case "-"   =>  "SUB"
            case "*"   =>  "MUL"
            case "/"   =>  "DIV"
            case "<<"  =>  "B_LSHIFT"
            case ">>"  =>  "B_RSHIFT"
            case "^"   =>  "B_XOR"
            case "&"   =>  "B_AND"
            case "|"   =>  "B_OR"
            
            case "[]=" =>  "IDX_ASS"
            case "+="  =>  "ADD_ASS"
            case "-="  =>  "SUB_ASS"
            case "*="  =>  "MUL_ASS"
            case "/="  =>  "DIV_ASS"
            case "<<=" =>  "B_LSHIFT_ASS"
            case ">>=" =>  "B_RSHIFT_ASS"
            case "^="  =>  "B_XOR_ASS"
            case "&="  =>  "B_AND_ASS"
            case "|="  =>  "B_OR_ASS"
            
            case "&&"  =>  "L_AND"
            case "||"  =>  "L_OR"
            case "%"   =>  "MOD"
            case "="   =>  "ASS"
            case "=="  =>  "EQ"
            case "<="  =>  "GTE"
            case ">="  =>  "LTE"
            case "!="  =>  "NE"
            case "!"   =>  "NOT"
            case "<"   =>  "LT"
            case ">"   =>  "GT"
            case "<=>" =>  "CMP"
            case "~"   =>  "B_NEG"
            case "as"  =>  "AS"
            
            case       =>  token throwError("Unknown overloaded symbol: %s" format(symbol)); "UNKNOWN"
        }
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    isScope: func -> Bool { true }
    
}
