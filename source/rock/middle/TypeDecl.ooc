import structs/HashMap
import ../frontend/Token
import Expression, Line, Type, Visitor, Declaration, VariableDecl,
    FunctionDecl, FunctionCall, Module

TypeDecl: abstract class extends Declaration {

    name: String
    type : static Type = BaseType new("Class", nullToken)
    externName: String = null

    variables := HashMap<VariableDecl> new()
    functions := HashMap<FunctionDecl> new()

    type: Type
    superType: Type
    
    module: Module = null
    
    init: func ~typeDecl (=name, =superType, .token) {
        super(token)
        type = BaseType new(name, token)
    }
    
    addVariable: func (vDecl: VariableDecl) {
        printf("Class %s just got variable %s\n", name, vDecl toString())
        variables put(vDecl name, vDecl)
        vDecl owner = this
    }
    
    addFunction: func (fDecl: FunctionDecl) {
        printf("Class %s just got function %s\n", name, fDecl toString())
        functions put(fDecl name, fDecl)
        fDecl owner = this
    }
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        functions get(fName)
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        variables get(vName)
    }
    
    underName: func -> String {
        // TODO underize it.
        if(!module) return name
        
        
    }
    
    getExternName: func -> String {
        return (externName && !externName isEmpty()) ? externName : name
    }
    
    isExtern: func -> Bool { externName != null }
    
    superRef: func -> TypeDecl {
        superType ? superType ref : null
    }
    
    getFunction: func ~call (call: FunctionCall) -> FunctionDecl {
        return getFunction(call name, call suffix, call)
    }
    
    getFunction: func ~nameSuffCall (name, suffix: String, call: FunctionCall) -> FunctionDecl {
        return getFunction(name, suffix, call, true);
    }
    
    getFunction: func ~nameSuffCallRec (name, suffix: String, call: FunctionCall, recursive: Bool) -> FunctionDecl {
        return getFunction(name, suffix, call, recursive, 0, null)
    }
    
    getFunction: func ~real (name, suffix: String, call: FunctionCall,
        recursive: Bool, bestScore: Int, bestMatch: FunctionDecl) -> FunctionDecl {
            
        for(fDecl: FunctionDecl in functions) {
            if(fDecl name equals(name) && (suffix == null || fDecl suffix equals(suffix))) {
                if(!call) return fDecl
                score := call getScore(fDecl)
                if(score == -1) return null
                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }
        }
        
        if(recursive && superRef()) {
            return superRef() getFunction(name, suffix, call, true, bestScore, bestMatch)
        }
        return bestMatch
        
    }
    
    getType: func -> Type { type }

}
