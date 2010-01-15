import Node

import Return, ClassDecl, CoverDecl, FunctionDecl, VariableDecl, Type,
        Module, If, Else, While, Foreach, RangeLiteral, CharLiteral,
        BoolLiteral, StringLiteral, IntLiteral, VariableAccess, FunctionCall,
        BinaryOp, Parenthesis, Return, Cast, Comparison, Ternary, Argument,
        AddressOf, Dereference

Visitor: abstract class {
    
    visitClassDecl:         func (node: ClassDecl)
    visitCoverDecl:         func (node: CoverDecl)
    visitFunctionDecl:      func (node: FunctionDecl)
    visitVariableDecl:      func (node: VariableDecl)
    
    visitType:              func (node: Type)
    
    visitModule:            func (node: Module)
    
    visitIf:                func (node: If)
    visitElse:              func (node: Else)
    visitWhile:             func (node: While)
    visitForeach:           func (node: Foreach)
    
    visitRangeLiteral:      func (node: RangeLiteral)
    visitCharLiteral:       func (node: CharLiteral)
    visitStringLiteral:     func (node: StringLiteral)
    visitBoolLiteral:       func (node: BoolLiteral)
    visitIntLiteral:        func (node: IntLiteral)
    
    visitVariableAccess:    func (node: VariableAccess)
    visitFunctionCall:      func (node: FunctionCall)
    
    visitBinaryOp:          func (node: BinaryOp)
    visitParenthesis:       func (node: Parenthesis)
    
    visitReturn:            func (node: Return)

    visitCast:              func (node: Cast)
    visitComparison:        func (node: Comparison)
    
    visitTernary:           func (node: Ternary)
    
    visitVarArg:            func (node: VarArg)
    
    visitAddressOf:         func (node: AddressOf)
    visitDereference:       func (node: Dereference)

}
