
import structs/ArrayList

import Expression, Statement, Scope, Var, Type
import tinker/Resolver

FuncDecl: class extends Expression {

    resolved := false // artificial testing
    name: String { get set }

    externName: String // null means non-extern, empty name means = regular name
    isExtern : Bool {
        get {
            externName != null
        }
    }
    
    body := Scope new()
    args := ArrayList<Var> new()
    retType := BaseType new("void")

    init: func ~fDecl (=name) {}

    resolve: func (task: Task) {
        task queueList(args)
        task queue(retType)
        resolved = true // artificial testing
        
        task queue(body)
        task done()
    }

    toString: func -> String {
        name + ": func"
    }

    getType: func -> Type {
        BaseType new("Func")
    }

}
