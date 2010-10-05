
import structs/[List, ArrayList]

import tinker/Resolver
import Statement, FuncDecl, Expression

Call: class extends Statement {

    name: String { get set }
    args: List<Expression> { get set }
    
    ref: FuncDecl

    init: func (=name) {
        args = ArrayList<Expression> new()
    }

    resolve: func (task: Task) {
        task queueList(args)
        
        sugg: CallSugg = null
        task walkBackward(|node|
            _sugg := sugg // yay workarounds

            if(!node callResolver?) return false // continue
            node resolveCall(this, task, |decl|
                _sugg = _sugg
                task need(func -> Bool {
                    decl resolved
                })
                if(_sugg) {
                    _sugg fight(decl)
                } else {
                    _sugg = CallSugg new(this, decl)
                }
            )
            sugg = _sugg
            false
        )
        if(!sugg)
            Exception new("Couldn't resolve call to " + name) throw()

        ref = sugg ref
        //("Resolved call to " + name + ", with decl " + ref name) println()
        task done()
    }

    getScore: func (decl: FuncDecl) -> Int {
        // yay dummy functions
        42
    }

    toString: func -> String {
        name + "()"
    }

}


CallSugg: class {

    call: Call
    ref: FuncDecl
    score: Int

    init: func (=call, =ref) {
        score = call getScore(ref)
    }

    fight: func (ref2: FuncDecl) {
        score2 := call getScore(ref2)
        if(score2 > score)
            ref = ref2
    }

}
