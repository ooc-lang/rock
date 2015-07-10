import structs/[Stack, ArrayList]
import ../[Node, Module, Statement, Scope, If, Else, BinaryOp,
    Return, VariableDecl, FunctionCall, VariableAccess, ControlStatement]

Trail: class extends Stack<Node> {

    init: func ~trail {
        super()
    }

    init: func ~trailWithModule (module: Module) {
        init()
        push(module)
    }

    /**
     * A checked pop, pops a node from the trail, and verify
     * it's equal to the reference node. It is used mostly as a
     * kind of assert, to make sure a subroutine didn't mess up the trail
     */
    pop: func ~verify (reference: Node) -> Node {

        popped: Node = pop()
        if(popped != reference) {
            Exception new(This, "Should have popped " +
                reference toString() + " but popped " + popped toString()) throw()
        }
        return popped

    }

    /**
     * Finds the nearest (from top to bottom) object of class T (or subclasses)
     * and return its index, or -1 if not found
     */
    find: func ~default (T: Class) -> Int {
        find(T, getSize() - 1)
    }

    onOuter: func <T> (T: Class, f: Func (T)) {
        idx := find(T)
        if(idx != -1) f(get(idx, T))
    }

    /**
     * Finds the nearest (from top to bottom) object of class T (or subclasses)
     * and return its index, or -1 if not found
     * Starting from index i
     */
    find: func (T: Class, i: Int) -> Int {
        while(i >= 0) {
            node := data get(i) as Node
            if(node class inheritsFrom?(T)) {
                break
            }
            i -= 1
        }

        return i

    }

    /**
     * The index of the nearest (from top to bottom) node that is a scope
     * (e.g. returns true to node isScope()), or -1 if we're not in a scope
     * at all.
     */
    findScope: func -> Int {

        i := getSize() - 1
        while(i >= 0) {
            node := data get(i) as Node
            if(node instanceOf?(Scope)) break
            i -= 1
        }

        return i

    }

    /**
     * Add a statement before the statement we're in, in the nearest
     * scope
     * @return true on success, false otherwise (e.g. not in a scope, or
     * addBefore() return false)
     * @see findScope()
     */
    addBeforeInScope: func (mark, newcomer: Statement) -> Bool {

        i := getSize() - 1
        while(i >= 0) {
            node := get(i)
            if(node instanceOf?(Scope)) {
                // if we're in an else - maybe we're in an if-else chain!
                if(i - 2 >= 0 && get(i - 1) instanceOf?(Else) && i + 1 < getSize() && get(i + 1) instanceOf?(If)) {

                    // the mark is now the Else. We wanna be before it!
                    mark = get(i - 1)
                    node = get(i - 2)

                    if(node instanceOf?(Scope)) {
                        // yup, definitely. Now, in that scope are several
                        // elses and ifs. We want to go to the previous statement
                        // until we encounter something that's not an if nor an else.
                        scope := node as Scope
                        idx := scope list indexOf(mark)

                        if(idx != -1) {
                            previous := scope list[idx - 1]
                            while(previous instanceOf?(If) || previous instanceOf?(Else)) {
                                idx -= 1
                                if(idx == 0) break
                                previous = scope list[idx - 1]
                            }

                            // we skipped'em all, now let's add the newcomer
                            // to the list and say we succeeded!
                            scope list add(idx, newcomer)
                            return true
                        }
                    }
                }

                if(node addBefore(i + 1 >= getSize() ? mark : get(i + 1), newcomer)) {
                    return true
                }
            }
            i -= 1
        }
        return false

    }

    /**
     * Add a statement after the statement we're in, in the nearest
     * scope
     * @return true on success, false otherwise (e.g. not in a scope, or
     * addAfter() return false)
     * @see findScope()
     */
    addAfterInScope: func (mark, newcomer: Statement) -> Bool {

        i := getSize() - 1
        while(i >= 0) {
            node := data get(i) as Node
            if(node instanceOf?(Scope) &&
               get(i) addAfter(i + 1 >= getSize() ? mark : get(i + 1), newcomer)) {
                return true
            }
            i -= 1
        }
        return false

    }

    /**
     * @return a textual representation of the trail, with a nice indented
     * formatting
     */
    toString: func -> String {

        sb := Buffer new()
        sb append('\n')

        for(i in 0..getSize()) {
            for(j in 0..i) {
                sb append("  ")
            }
            sb append("\\_, "). append(get(i) toString()). append('\n')
        }

        sb toString()

    }

    /**
     * @return true when `node`'s parent is a BinaryOp, of one of the
     * assignment types, and `node` is on the left-hand side (ie. being
     * assigned to)
     */
    isLHS: func (node: Node) -> Bool {
        match (parent := peek()) {
            case bop: BinaryOp =>
                return bop isAssign() && bop left == node
        }
        false
    }

    /**
     * @return true when `node`'s parent is a BinaryOp, of one of the
     * assignment types, and `node` is on the right-hand side (ie. being
     * assigned)
     */
    isRHS: func (node: Node) -> Bool {
        match (parent := peek()) {
            case bop: BinaryOp =>
                return bop isAssign() && bop right == node
        }
        false
    }

    /**
     * Delegate for data get(index)
     */
    get: func (index: Int) -> Node {
        if (index < 0) {
            Exception new(This, "Negative index in Trail get: #{index}") throw()
        }
        return data get(index) as Node
    }

    get: func ~checked <T> (index: Int, T: Class) -> T {
        if (index < 0) {
            Exception new(This, "Negative index in Trail get~checked: #{index}") throw()
        }
        node := data get(index) as Node
        if(!node instanceOf?(T)) {
            Exception new(This, "In Trail get(), expecting getting %s, got %s\n" format(T name, node class name)) throw()
        }
        return node
    }

    /**
     * Returns the 0th element of the trail, which should always
     * be a Module
     */
    module: func -> Module { data get(0) as Module }

    /**
     * @return a clone of this trail
     */
    clone: func -> This {
        copy := new()
        copy data = data clone()
        copy
    }

}
