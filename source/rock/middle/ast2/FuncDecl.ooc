
import structs/ArrayList

import Node, Statement, Call, Scope, Var
import tinker/Resolver

FuncDecl: class extends Node {

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

    init: func ~fDecl (=name) {}

    resolve: func (task: Task) {
        task queueList(args)
        resolved = true // artificial testing
        
        task queue(body)
        task done()
    }

    toString: func -> String {
        name + ": func"
    }

}
