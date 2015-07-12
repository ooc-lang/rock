import structs/[ArrayList]
import VariableAccess, VariableDecl, Statement, Node, Visitor,
       FunctionCall, Type, FuncType, Version, BaseType, Tuple
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
        resolveName(type getName(), list size, res, trail, |vDecl|
            type suggest(vDecl)
        )
    }

    /**
     * @return true if this scope contains a variable declaration with
     * the name `name`, false otherwise
     */
    containsDeclaration?: func (name: String) -> Bool {
        for (stmt in list) {
            match stmt {
                case vd: VariableDecl =>
                    if (vd hasName?(name)) return true
            }
        }
        false
    }

    /**
     * @return true if this scope contains `stmt`
     */
    contains?: func (stmt: Statement) -> Bool {
        list contains?(stmt)
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        index := -1
        ourIndex := trail indexOf(this)

        if(ourIndex != -1) {
            node : Statement = null

            if(ourIndex + 1 >= trail getSize()) {
                // 'access' is a direct child of us
                node = access
            } else {
                // 'access' is within another statement
                node = trail get(ourIndex + 1)
            }
            index = list indexOf(node)
        }

        resolveName(access getName(), index, res, trail, |vDecl|
            access suggest(vDecl)
        )
    }

    resolveName: func (name: String, index: Int, res: Resolver, trail: Trail, cb: Func (VariableDecl) -> Bool) -> Int {
        // probably a global
        if (index == -1) {
            index = list size
        }

        for((i, candidate) in list) {
            // don't count variables declared after index
            if (i >= index) break

            match candidate {
                // a VariableDeclTuple is like a chrysalis from which a
                // beautiful pupa VariableDecl eventually emerges. While
                // it's still in chrysalis form, though, we gently let
                // the VariableAccess know it's not ready yet. cf. #903
                case vDeclTuple: VariableDeclTuple =>
                    if (vDeclTuple hasName?(name)) return -1

                case vDecl: VariableDecl =>
                    if (vDecl hasName?(name)) {
                        if(cb(vDecl)) return 1
                    }

                case vb: VersionBlock =>
                    // version blocks don't introduce a new scope,
                    // let them resolve access in their entire body
                    result := vb getBody() resolveName(name, -1, res, trail, cb)
                    if (result != 0) return result
            }
        }

        0
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        for(stat in this) {
            match stat {
                case vDecl: VariableDecl =>
                    // can call funcTypes (C functions) or closures (anonymous ooc functions w/context)
                    declType := vDecl getType()
                    if (declType == null) continue

                    funcType    := declType instanceOf?(FuncType)
                    closureType := declType getName() == "Closure"

                    if((funcType || closureType) && vDecl name == call name) {
                        if (call suggest(vDecl getFunctionDecl(), res, trail)) {
                            break
                        }
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
                if(res params veryVerbose) "Response of statement [%s] %s = %s" printfln(stat class name, stat toString(), response toString())
                trail pop(this)
                return response
            }
        }

        trail pop(this)
        return Response OK

    }

    addFirst: func (newcomer: Statement) -> Bool {
        add(0, newcomer)
        true
    }

    addBefore: func (mark, newcomer: Statement) -> Bool {
        idx := indexOf(mark)
        if(idx != -1) {
            add(idx, newcomer)
            return true
        }

        return false
    }

    addAfter: func (mark, newcomer: Statement) -> Bool {
        idx := indexOf(mark)
        if (idx == -1) {
            return false
        }

        add(idx + 1, newcomer)
        true
    }

    add:      func ~append (n: Statement) { list add(n) }
    remove:   func (n: Statement) -> Bool { list remove(n) }
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

