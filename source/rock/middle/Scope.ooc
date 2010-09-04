import structs/[ArrayList]
import VariableAccess, VariableDecl, Statement, Node, Visitor,
       FunctionCall, Type, FuncType, Version, BaseType
import tinker/[Trail, Resolver, Response]
import ../frontend/[BuildParams, Token]

Scope: class extends Node {
	
	size: SSizeT {
		get {
			list getSize()
		}
	}

    list : ArrayList<Statement> { get set }

    init: func ~scope {
        list = ArrayList<Statement> new()
    }

    clone: func -> This {
        copy := new()
        list each(|e| copy list add(e clone()))
        copy
    }

    each: func (f: Func (Statement)) {
        list each(f)
    }

    accept: func (v: Visitor) { v visitScope(this) }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        va: static VariableAccess
        
        if(!va) va = VariableAccess new(null, nullToken)
        va name = type getName()
        va ref = null
        
        if(resolveAccess(va, res, trail) == -1) return -1
        if(va ref) type suggest(va ref)

        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        index := list getSize()
        ourIndex := trail indexOf(this)

        if(ourIndex != -1) {
            node : Statement = null

            if(ourIndex + 1 >= trail getSize()) node = access
            else                             node = trail get(ourIndex + 1)
            index = list indexOf(node)
        }

        // probably a global
        if(index == -1) index = list getSize()

        for(i in 0..index) {
            candidate := list get(i)
            if(candidate instanceOf?(VariableDecl) && candidate as VariableDecl getName() == access getName()) {
                if(access suggest(candidate as VariableDecl)) {
                    return 0
                }
            } else if(candidate instanceOf?(VersionBlock)) {
                vb := candidate as VersionBlock
                for(stmt in vb getBody()) {
                    if(stmt instanceOf?(VariableDecl) && stmt as VariableDecl getName() == access getName()) {
                        //printf("Suggesting %s from version block %s\n", stmt toString(), vb toString())
                        if(access suggest(stmt as VariableDecl)) {
                            return 0
                        }
                    }
                }
            }
        }

        0
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        // FIXME: this is as wrong as resolveAccess, see the comments up there.

        for(stat in this) {
            if(stat instanceOf?(VariableDecl)) {
                vDecl := stat as VariableDecl
                // experimental
                if((vDecl getType() instanceOf?(FuncType) || (vDecl getType() != null && vDecl type getName() == "Closure")) &&
                    vDecl name == call name &&
                    call suggest(vDecl getFunctionDecl(), res, trail)) {
                        break
                }
            }
        }

        // see the definition of resolveCall in Node
        return 0
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        for(stat in this) {
            response := stat resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of statement [%s] %s = %s\n", stat class name toCString(), stat toString() toCString(), response toString() toCString())
                trail pop(this)
                return response
            }
        }

        trail pop(this)
        return Response OK

    }

    addBefore: func (mark, newcomer: Statement) -> Bool {

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

    addAfter: func (mark, newcomer: Statement) -> Bool {

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
    removeAt: func (i: Int) -> Statement  { list removeAt(i) }

    iterator: func -> Iterator<Statement> {
        list iterator()
    }

    empty?:  func -> Bool { list empty?() }

    last:  func -> Statement { list last() }
    first: func -> Statement { list first() }

    lastIndex: func -> Int { list lastIndex() }

    get: func (i: Int) -> Statement  { list get(i) }
    set: func (i: Int, s: Statement) { list set(i, s) }
    add: func ~withIndex (i: Int, s: Statement) { list add(i, s) }

    addAll: func (s: Scope) { list addAll(s list) }

    indexOf: func (s: Statement) -> Int { list indexOf(s) }

    replace: func (oldie, kiddo: Statement) -> Bool { list replace(oldie, kiddo) }

    getSize: func -> Int { list getSize() }

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
        sb append(" }")
        sb toString()
    }

}

