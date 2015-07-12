import Visitor, FunctionCall, VariableAccess, VariableDecl, Type, BaseType,
       Module, Expression
import ../frontend/Token
import tinker/[Resolver, Response, Trail]

/**
 * An AST node, such as a statement, an expression, a directive,
 * a value, etc.
 */
Node: abstract class {

    /**
     * If the node was parsed, corresponds to the place in an ooc source
     * file where it was parsed from.
     *
     * Token is a cover, so it can't be null, but it can have all-zero values
     * and a null module (see `nullToken` near Token's definition)
     */
    token: Token

    init: func (=token)

    /**
     * Visitor pattern implementation a-la Java
     */
    accept: abstract func (visitor: Visitor)

    /**
     * @return a human-readable representation of that AST node
     */
    toString: func -> String { class name }

    /* METHODS FOR TINKERING */

    /**
     * @return true when, as far as we know, the node has been resolved
     * Note: don't rely on this too much, it's too simplistic to fit
     * rock's resolve process
     */
    isResolved: func -> Bool { true }

    /**
     * Should be called when a node's hierarchy has been changed and it might
     * need to re-resolve some stuff.
     * No-op by default, override where it makes sense
     */
    refresh: func

    /**
     * Resolve a node.
     * @return Response LOOP if we really need to loop now, Response OK if we
     * can continue resolving the rest.
     */
    resolve: func (trail: Trail, res: Resolver) -> Response {
        Response OK
    }

    /* METHODS FOR SCOPE-LIKES */

    /**
     * In the 'children' of this node, replace 'oldie' with 'kiddo'.
     * No-op by default, should be overloaded where it makes sense
     * @return true if the replacement was successful
     */
    replace: abstract func (oldie, kiddo: Node) -> Bool

    /**
     * In the 'children' of this node, add 'newcomer' at the beginning.
     * No-op by default, should be implemented by scope-likes
     * @return true if newcomer was added correctly
     */
    addFirst: func (newcomer: Node) -> Bool { false }

    /**
     * In the 'children' of this node, add 'newcomer' before 'mark'
     * No-op by default, should be implemented by scope-likes
     * @return true if newcomer was added correctly
     */
    addBefore: func (mark, newcomer: Node) -> Bool { false }

    /**
     * In the 'children' of this node, add 'newcomer' before 'mark'
     * No-op by default, should be implemented by scope-likes
     * @return true if newcomer was added correctly
     */
    addAfter:  func (mark, newcomer: Node) -> Bool { false }

    /**
     * @return true if this is a scope.
     */
    isScope: func -> Bool { false }

    /**
     * Looks for a function declaration satisfying `call`, and suggests it with
     * call suggest(fDecl)
     *
     * No-op by default, should be overloaded where it makes sense
     *
     * @return -1 if unresolved types prevented the call resolving process from
     * finishing, and it should be repeated later, any other value otherwise
     */
    resolveCall: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {
        0
    }

    /**
     * Looks for a declaration statisfying `access`, and suggests it with
     * access suggest(decl)
     *
     * No-op by default, should be overloaded where it makes sense
     *
     * @return -1 if unresolved things prevented the access resolving process from
     * finishing, and it should be repeated later, any other value otherwise.
     */
    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        0
    }

    /**
     * Looks for a type declaration statisfying `type`, and suggests it with
     * type suggest(decl)
     *
     * No-op by default, should be overloaded where it makes sense
     *
     * @return -1 if unresolved things prevented the type resolving process from
     * finishing, and it should be repeated later, any other value otherwise.
     */
    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        // overridden in sub-classes
        0
    }

    /**
     * Generate a symbol name by prefixing it with the module's underName and
     * the `origin` parameter.
     *
     * Uses a per-module numeric seed to avoid collisions.
     */
    generateTempName: func (origin: String) -> String {
        token module tempNameSeed += 1
        "__%s_%s%d" format(token module underName, origin, token module tempNameSeed)
    }

    /**
     * @return true if the thing contained itself has side effects.
     *
     * For example, literals don't have side effects, function calls
     * might, assignments definitely do.
     */
    hasSideEffects: func -> Bool { true }

    /**
     * Clone this node, so that it may be used somewhere else in the AST
     * without any modification to the clone hurting the original node.
     *
     * Implementing this correctly is crucial to functionality that heavily
     * uses cloning such as cover templates, inlining, etc.
     *
     * @return a clone of this node.
     */
    clone: abstract func -> This

    /**
     * Translate stuff like '__quest' and '__bang' back into '?' and '!'
     *
     * @return The 'prettified' name, as it appeared in the source
     */
    unbangify: static func (name: String) -> String {
      match {
        case name endsWith?("__quest") =>
          name[0..-8] + "?"
        case name endsWith?("__bang") =>
          name[0..-7] + "!"
        case =>
          name
      }
    }

    /**
     * @return true if this node reads from `expr`
     */
    hasExpr?: func (expr: Expression) -> Bool {
        false
    }

    /**
     * Try to infer the required type for a given expression, if any
     */
    typeForExpr: func (trail: Trail, expr: Expression, target: Type@) -> SearchResult {
        SearchResult NONE
    }

}

/**
 * Used as a return value on various methods that can be called
 * while resolving a node.
 */
BranchResult: enum {
    /** All good, keep going */
    CONTINUE

    /** 'resolveAgain' was called, return 'Response OK' and break */
    BREAK

    /** 'resolveAgain' was called, return 'Response LOOP' and break */
    LOOP
}

/**
 * Used as a return value for methods supposed to find something.
 */
SearchResult: enum {
    /** Retry later, not enough info yet */
    RETRY

    /** Didn't find anything */
    NONE

    /** Found something! */
    FOUND
}

