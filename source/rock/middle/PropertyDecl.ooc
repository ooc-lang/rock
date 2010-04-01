import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument, BinaryOp, Cast, Module,
       Block, Scope, FunctionDecl, Argument, VariableDecl
import tinker/[Response, Resolver, Trail]
import ../frontend/BuildParams

PropertyDecl: class extends VariableDecl {
    init: func ~pDecl (.type, .name, .token) {
        init(type, name, null, token)
    }
}
