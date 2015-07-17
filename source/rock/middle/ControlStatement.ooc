import structs/ArrayList
import ../frontend/Token
import Statement, Scope, VariableAccess, Node
import tinker/[Trail, Resolver, Response]

ControlStatement: abstract class extends Statement {

    body := Scope new()

    init: func ~controlStatement (.token) {
        body token = token
        super(token)
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        // FIXME: this probably isn't needed. Harmful, even.
        body resolveAccess(access, res, trail)
        0
    }

    resolveBody: func (trail: Trail, res: Resolver) -> BranchResult {
        trail push(this)
        result := body resolve(trail, res)
        trail pop(this)

        if (result == Response LOOP) {
            return BranchResult LOOP
        }

        if (!body isResolved()) {
            res wholeAgain(this, "waiting on body to resolve")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        body replace(oldie, kiddo)
    }

    addFirst: func (newcomer: Node) -> Bool {
        body addFirst(newcomer)
    }

    addBefore: func (mark, newcomer: Node) -> Bool {
        body addBefore(mark, newcomer)
    }

    addAfter: func (mark, newcomer: Node) -> Bool {
        body addAfter(mark, newcomer)
    }

    add: func (newcomer: Statement) {
        body add(newcomer)
    }

    /**
     * If, Else, Match are dead-end control statements.
     * While, For, Foreach aren't.
     *
     * A dead-end control statement is explored by autoReturn(TM),
     * to add return when the last statement is a non-void expression.
     */
    isDeadEnd: func -> Bool { false }

    getBody: func -> Scope { body }

}
