import structs/[ArrayList], text/Buffer
import VariableAccess, VariableDecl, Statement, Node, Visitor,
       FunctionCall, Type
import tinker/[Trail, Resolver, Response]
import ../frontend/[BuildParams]

Scope: class extends Node {
    
    list := ArrayList<Statement> new()
    
    init: func ~scope {}
    
    accept: func (v: Visitor) { v visitScope(this) }
    
    resolveAccess: func (access: VariableAccess) {
        // FIXME: this is *wrong* because the following code would compile with it:
        //
        // main: func {
        //   printf("%d", x)
        //   x := 42 // x is declared *after* it's used but it doesn't complain..
        // }
        //
        // even worse, the following code would also compile:
        //
        // main: func {
        //   for(i in 0..3) {
        //     // do things
        //   }
        //   printf("%d", i) // i is not even in the scope, but it doesn't complain..
        // }
        
        for(stat in this) {
            stat resolveAccess(access)
        }
    }
    
    resolveCall: func (call: FunctionCall) {
        // FIXME: this is as wrong as resolveAccess, see the comments up there.
        // KALAMAZOO

        for(stat in this) {
            if(stat instanceOf(VariableDecl)) {
                vDecl := stat as VariableDecl
                if(vDecl getType() instanceOf(FuncType) &&
                   vDecl getName() == call getName() &&
                   call suggest(vDecl getFunctionDecl())) {
                    break
                }
            }
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        for(stat in this) {
            response := stat resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of statement [%s] %s = %s\n", stat class name, stat toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        return Responses OK
        
    }
    
    addBefore: func (mark, newcomer: Node) -> Bool {
        
        //printf("Should add %s before %s\n", newcomer toString(), mark toString())
        
        idx := indexOf(mark)
        //printf("idx = %d\n", idx)
        if(idx != -1) {
            add(idx, newcomer)
            //println("|| adding newcomer " + newcomer toString() + " at idx " + idx toString())
            return true
        }
        
        return false
        
    }
    
    addAfter: func (mark, newcomer: Node) -> Bool {
        
        //printf("Should add %s after %s\n", newcomer toString(), mark toString())
        
        idx := indexOf(mark)
        //printf("idx = %d\n", idx)
        if(idx != -1) {
            add(idx + 1, newcomer)
            //println("|| adding newcomer " + newcomer toString() + " at idx " + (idx + 1) toString())
            return true
        }
        
        return false
        
    }
    
    add:      func ~append (n: Statement) { list add(n) }
    remove:   func (n: Statement) { list remove(n) }
    removeAt: func (i: Int)       { list removeAt(i) }
    
    iterator: func -> Iterator<Statement> {
        list iterator()
    }
    
    isEmpty:  func -> Bool { list isEmpty() }
    
    last:  func -> Statement { list last() }
    first: func -> Statement { list first() }
    
    lastIndex: func -> Int { list lastIndex() }

    get: func (i: Int) -> Statement  { list get(i) }
    set: func (i: Int, s: Statement) { list set(i, s) }
    add: func (i: Int, s: Statement) { list add(i, s) }
    
    addAll: func (s: Scope) { list addAll(s list) }
    
    indexOf: func (s: Statement) -> Int { list indexOf(s) }
    
    replace: func (oldie, kiddo: Node) -> Bool { list replace(oldie, kiddo) }
    
    size: func -> Int { list size() }
    
    isScope: func -> Bool { true }
    
    toString: func -> String {
        sb := Buffer new()
        sb append('{')
        isFirst := true
        for(stmt in list) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            sb append(stmt toString())
        }
        sb append('}')
        sb toString()
    }
    
}

