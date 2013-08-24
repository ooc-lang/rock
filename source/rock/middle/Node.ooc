import Visitor, FunctionCall, VariableAccess, VariableDecl, Type, BaseType
import ../frontend/Token
import tinker/[Resolver, Response, Trail]

Node: abstract class {

    nameSeed := static 0

    token: Token

    init: func(=token) {}

    accept: abstract func (visitor: Visitor)

    toString: func -> String { class name }

    isResolved: func -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response { return Response OK }

    replace: abstract func (oldie, kiddo: Node) -> Bool

    addFirst: func (newcomer: Node) -> Bool { false }
    addBefore: func (mark, newcomer: Node) -> Bool { false }
    addAfter:  func (mark, newcomer: Node) -> Bool { false }

    isScope: func -> Bool { false }

    getRequiredType: func -> Type { null }

    /**
     * resolveCall should look for a function declaration satisfying call,
     * and suggest it with call suggest(fDecl)
     *
     * :return: -1 if unresolved types prevented the call resolving
     * process from finishing, and it should be repeated later, any
     * other value else.
     */
    resolveCall: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {
        // overridden in sub-classes
        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        // overridden in sub-classes
        0
    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        // overridden in sub-classes
        0
    }

    generateTempName: func (origin: String) -> String {
        nameSeed += 1
        "__%s%d" format(origin, nameSeed)
    }

    // Just to be on the safe side - everything has side effects by default
    hasSideEffects : func -> Bool { true }

    /**
     * Clone this node, so that it may be used somewhere else in the AST
     * without any modification to the clone hurting the original node.
     *
     * @return a clone of this node.
     */
    clone: abstract func -> This

    /**
     * Translate stuff like __quest and __bang back into '?' and '!'
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

}
