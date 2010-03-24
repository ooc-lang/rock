import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node,
       VariableAccess, VariableDecl, IntLiteral, Type, RangeLiteral,
       FunctionCall, Block, Scope, While, BinaryOp
import tinker/[Trail, Resolver, Response]

Foreach: class extends ControlStatement {
    
    variable: Expression
    collection: Expression
    
    replaced := false

    init: func ~_foreach (=variable, =collection, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitForeach(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case variable   => variable   = kiddo; replaced = true; return true
            case collection => collection = kiddo; return true
        }
        return super(oldie, kiddo)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(variable instanceOf(VariableAccess) && !replaced) {
            varType : Type = null
            if(collection instanceOf(RangeLiteral)) {
                varType = IntLiteral type
            }
            variable = VariableDecl new(varType, variable as VariableAccess getName(), variable token)
        }
        
        trail push(this)
        
        {
            response := variable resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := collection resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        if(!collection instanceOf(RangeLiteral)) {
            if(collection getType() == null) {
                res wholeAgain(this, "need collection type")
                return Responses OK
            }
            collection getType() resolve(trail, res)

            iterCall := FunctionCall new(collection, "iterator", token)
            
            response := Responses LOOP
            while(response == Responses LOOP) {
                response = iterCall resolve(trail, res)
            }
            //printf("iterCall = %s, ref = %s\n", iterCall toString(), iterCall getRef() ? iterCall getRef() toString() : "(nil)")
            
            iterType := iterCall getType()
            if(iterType == null) {
                if(res fatal) token throwError("Couldn't resolve iterType %s" format(iterType))
                res wholeAgain(this, "need iterType")
                return Responses OK
            }
            iterType resolve(trail, res)
            if(!iterType isResolved()) {
                if(res fatal) token throwError("Couldn't resolve iterType %s" format(iterType))
                res wholeAgain(this, "need iterType")
                return Responses OK
            }
            
            list := trail get(trail findScope()) as Node
            block := Block new(token)
            
            vdfe := VariableDecl new(iterType, generateTempName("iter"), iterCall, token)
            iterAcc := VariableAccess new(vdfe, token)
            
            hasNextCall := FunctionCall new(iterAcc, "hasNext", token)
            hasNextCall resolve(trail, res)
            
            while1 := While new(hasNextCall, token)
            
            nextCall := FunctionCall new(iterAcc, "next", token)
            nextCall resolve(trail, res)
            
            while1 getBody() add(BinaryOp new(variable, nextCall, OpTypes ass, token)).
                             addAll(getBody())
            
            if(!list replace(this, block)) {
                if(res fatal) printf("Failed to replace %s with %s in a %s. trail = %s", toString(), block toString(), list toString(), trail toString())
                res wholeAgain(this, "Can't turn into a while :/, list = " + list toString() + " (it's a " + list class name)
                return Responses LOOP
            }
            
            block getBody() add(vdfe).
                            add(while1)

            if(variable getType() == null) {
                decl : VariableDecl = variable
                if(!variable instanceOf(VariableDecl)) {
                    acc := variable as VariableAccess
                    decl = acc ref
                }
                decl setType(nextCall getType())
            }
                            
            //res wholeAgain(this, "Just turned into a while =)")
            //return Responses OK
            return Responses LOOP
        }
        
        return super(trail, res)
        
    }
    
    resolveAccess: func (access: VariableAccess) {
        
        if(variable instanceOf(VariableDecl)) {
            vDecl := variable as VariableDecl
            if(vDecl name == access name && access suggest(vDecl)) return
        }
        super(access)
        
    }
    
    toString: func -> String { "for (" + variable toString() + " in " + collection toString() + ")" }
    
}
