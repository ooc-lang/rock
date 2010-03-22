import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp
import tinker/[Trail, Resolver, Response]

Match: class extends Expression {
    
    type: Type = null
    expr: Expression = null
    cases := ArrayList<Case> new()

    init: func ~match_ (.token) {
        super(token)
    }
    
    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}
    
    getCases: func -> List<Case> { cases }
    
    addCase: func (caze: Case) {
        cases add(caze)
        
        if(expr && caze getExpr()) {
            // hideous, but obvious
            if(!(expr instanceOf(BoolLiteral) && expr as BoolLiteral getValue() == true)) {
                caze setExpr(Comparison new(expr, caze getExpr(), CompTypes equal, caze getExpr() token))
            }
        }
    }
    
    accept: func (visitor: Visitor) {
        visitor visitMatch(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case      => false
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if (expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }
        
        trail push(this)
        for (caze in cases) {
            response := caze resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        printf("[Match] resolving match!! trail peek() = %s\n", trail peek() class name)
        if(!trail peek() instanceOf(Scope)) {
            if(type == null) {
                printf("[Match] So far, type of match = %s\n", type ? type toString() : "(nil)")
                response := inferType(trail, res)
                if(!response ok()) {
                    return response
                }
                if(type == null && !(trail peek() instanceOf(Scope))) {
                    if(res fatal) token throwError("Couldn't figure out type of match")
                    res wholeAgain(this, "need to resolve type")
                    return Responses OK
                }
            }
            
            if(type != null) {
                vDecl := VariableDecl new(type, generateTempName("match"), token)
                varAcc := VariableAccess new(vDecl, token)
                trail addBeforeInScope(this, vDecl)
                trail addBeforeInScope(this, this)
                trail peek() replace(this, varAcc)
                for(caze in cases) {
                    ass := BinaryOp new(varAcc, caze getBody() last(), OpTypes ass, caze token)
                    caze getBody() set(caze getBody() lastIndex(), ass)
                }
                res wholeAgain(this, "just unwrapped")
                return Responses OK
            }
        }

        return Responses OK
        
    }
    
    inferType: func (trail: Trail, res: Resolver) -> Response {
        
		funcIndex   := trail find(FunctionDecl)
		returnIndex := trail find(Return)
		
        printf("[Match inferType] funcIndex = %d, returnIndex = %d\n", funcIndex, returnIndex)
		if(funcIndex != -1 && returnIndex != -1) {
			funcDecl := trail get(funcIndex) as FunctionDecl
			if(funcDecl getReturnType() isGeneric()) {
				type = funcDecl getReturnType()
			}
		}
		
		if(type == null) {
			// TODO make it more intelligent e.g. cycle through all cases and
			// check that all types are compatible and find a common denominator
			if(cases isEmpty()) return
            
            first := cases first()
			if(first getBody() isEmpty()) return
			statement := first getBody() first()
			if(!statement instanceOf(Expression)) return
			type = statement as Expression getType()
            printf("Got type %s\n", type toString())
		}
        
        return Responses OK
		
    }
    
    getType: func -> Type { type }
    
    toString: func -> String { class name }
    
}

Case: class extends ControlStatement {

    expr: Expression

    init: func ~_case (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) {}
    
    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}
    
    resolveAccess: func (access: VariableAccess) {
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if (expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }
        
        return body resolve(trail, res)
        
    }
    
}

