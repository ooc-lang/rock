import structs/[ArrayList]
import ../frontend/[Token, BuildParams]
import Visitor, Expression, VariableDecl, Declaration, Type, Node,
       OperatorDecl, FunctionCall, Import, Module, BinaryOp,
       VariableAccess, AddressOf, ArrayCreation, TypeDecl
import tinker/[Resolver, Response, Trail]

ArrayAccess: class extends Expression {

    array, index: Expression
    type: Type = null
    
    getArray: func -> Expression { array }
    setArray: func (=array) {}
    getIndex: func -> Expression { index }
    setIndex: func (=index) {}
    
    init: func ~arrayAccess (=array, =index, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitArrayAccess(this)
    }
    
    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { false }
    
    getGenericOperand: func -> Expression {
        if(getType() isGeneric() && getType() pointerLevel() == 0) {
            sizeAcc := VariableAccess new(VariableAccess new(getType() getName(), token), "size", token)
            arrAcc := this as ArrayAccess
            // FIXME: wtf? we're modifying 'this' instead of making a copy of it?
            arrAcc setIndex(BinaryOp new(arrAcc getIndex(), sizeAcc, OpTypes mul, arrAcc token))
            return AddressOf new(arrAcc, arrAcc token)
        }
        return super()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        if(!index resolve(trail, res) ok()) {
            res wholeAgain(this, "because of index!")
        }
        if(!array resolve(trail, res) ok()) {
            res wholeAgain(this, "because of array!")
        }
        
        trail pop(this)
        
        // TODO: put that in a function
        if(!handleArrayCreation(trail, res) ok()) {
            return Responses LOOP
        }
        
        {
            response := resolveOverload(trail, res)
            if(!response ok()) {
                res wholeAgain(this, "overload says some things aren't resolved yet")
                return Responses OK
            }
        }
        
        if(array getType() == null) {
            res wholeAgain(this, "because of array type!")
        } else {            
            type = array getType() dereference()
            if(type == null) {
                res wholeAgain(this, "because of array dereference type!")
            }
        }
        
        return Responses OK
        
    }
    
    handleArrayCreation: func (trail: Trail, res: Resolver) -> Response {
        
        deepDown := this as Expression
        while(deepDown instanceOf(ArrayAccess)) {
            deepDown = deepDown as ArrayAccess array
        }
        
        if(deepDown instanceOf(VariableAccess) && deepDown as VariableAccess getRef() instanceOf(TypeDecl)) {
            varAcc := deepDown as VariableAccess
            tDecl := varAcc getRef() as TypeDecl
            innerType := tDecl getInstanceType()
            
            parent := trail peek()
            
            if(!parent instanceOf(FunctionCall)) {
                if(parent instanceOf(ArrayAccess)) {
                    // will be taken care of later
                    return Responses OK
                }
                token throwError("Unexpected ArrayAccess to a type, parent is a %s, ie. %s" format(parent class name, parent toString()))
            }
            
            fCall := parent as FunctionCall
            if(fCall getName() != "new") {
                token throwError("Good lord, what are you trying to call on that array type?")
            }
            
            grandpa := trail peek(2)
            
            arrayType := ArrayType new(innerType, index, token)
            
            deepDown = array
            while(deepDown instanceOf(ArrayAccess)) {
                arrAcc := deepDown as ArrayAccess
                arrayType = ArrayType new(arrayType, arrAcc index, token)
                deepDown = deepDown as ArrayAccess array
            }
            arrayCreation := ArrayCreation new(arrayType, token)
            
            // TODO: this is all very hackish. More checking is needed
            if(grandpa instanceOf(VariableDecl)) {
                vDecl := grandpa as VariableDecl
                vAcc := VariableAccess new(vDecl, token)
                if(vDecl isMember()) {
                    if(vDecl isStatic()) {
                        vAcc expr = VariableAccess new(vDecl getOwner() getInstanceType(), token)
                    } else {
                        vAcc expr = VariableAccess new("this", token)
                    }
                }
                arrayCreation expr = vAcc
            } else if(grandpa instanceOf(BinaryOp)) {
                arrayCreation expr = grandpa as BinaryOp getLeft()
            }
            grandpa replace(fCall, arrayCreation)
            
            // TODO: do we really need a LOOP here? Wouldn't a wholeAgain+OK suffice?
            return Responses LOOP
            
        }
        
        return Responses OK
        
    }
    
    resolveOverload: func (trail: Trail, res: Resolver) -> Response {
        
        /*
        printf("Looking for an overload of %s[%s], %s\n",
            array getType() ? array getType() toString() : "(nil)",
            index getType() ? index getType() toString() : "(nil)",
            array getType() && array getType() getRef() ? array getType() getRef() toString() : "(nil)")
        */
        
        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)
        
        bestScore := 0
        candidate : OperatorDecl = null
        
        parent := trail peek()
        reqType := parent getRequiredType()
        
        inAssign := (parent instanceOf(BinaryOp)) &&
                    (parent as BinaryOp isAssign()) &&
                    (parent as BinaryOp getLeft() == this)
        
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl, reqType, inAssign)
            if(score == -1) return Responses LOOP
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl, reqType, inAssign)
                if(score == -1) return Responses LOOP
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
            fCall getArguments() add(array)
            fCall getArguments() add(index)
            
            if(inAssign) {
                assign := parent as BinaryOp
                fCall getArguments() add(assign getRight())
                
                if(!trail peek(2) replace(assign, fCall)) {
                    token throwError("Couldn't replace %s with %s in %s!" format(assign toString(), fCall toString(), trail peek(2) as Node class name))
                }
            } else {
                if(!trail peek() replace(this, fCall)) {
                    token throwError("Couldn't replace %s with %s!" format(toString(), fCall toString()))
                }
            }
            
            res wholeAgain(this, "Just been replaced with an overload")
            return Responses LOOP
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type, inAssign: Bool) -> Int {
        
        if(!(op getSymbol() equals(inAssign ? "[]=" : "[]"))) {
            return 0 // not the right overload type - skip
        }
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        /*
        if(args size() != 2) {
            op token throwError(
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args size()))
        }
        */
        
        opArray  := args get(0)
        opIndex := args get(1)

        if(opArray getType() == null || opIndex getType() == null || array getType() == null || index getType() == null) {
            return -1
        }
        
        arrayScore := array getType() getScore(opArray getType())
        if(arrayScore == -1) return -1
        indexScore := index getType() getScore(opIndex getType())        
        if(indexScore == -1) return -1
        reqScore   := reqType ? fDecl getReturnType() getScore(reqType) : 0
        if(reqScore   == -1) return -1
        
        return arrayScore + indexScore + reqScore
        
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
