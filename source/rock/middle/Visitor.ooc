import Node

import Return, ClassDecl, CoverDecl, FunctionDecl, VariableDecl, Type,
        Module, If, Else, While, Foreach, RangeLiteral, CharLiteral,
        BoolLiteral, StringLiteral, IntLiteral, VariableAccess, FunctionCall,
        BinaryOp, Parenthesis, Line, Return, Cast, Comparison, Ternary

Visitor: abstract class {
    
    visitClassDecl:         abstract func (node: ClassDecl)
    visitCoverDecl:         abstract func (node: CoverDecl)
    visitFunctionDecl:      abstract func (node: FunctionDecl)
    visitVariableDecl:      abstract func (node: VariableDecl)
    
    visitType:              abstract func (node: Type)
    
    visitModule:            abstract func (node: Module)
    
    visitIf:                abstract func (node: If)
    visitElse:              abstract func (node: Else)
    visitWhile:             abstract func (node: While)
    visitForeach:           abstract func (node: Foreach)
    
    visitRangeLiteral:      abstract func (node: RangeLiteral)
    visitCharLiteral:       abstract func (node: CharLiteral)
    visitStringLiteral:     abstract func (node: StringLiteral)
    visitBoolLiteral:       abstract func (node: BoolLiteral)
    visitIntLiteral:        abstract func (node: IntLiteral)
    
    visitVariableAccess:    abstract func (node: VariableAccess)
    visitFunctionCall:      abstract func (node: FunctionCall)
    
    visitBinaryOp:          abstract func (node: BinaryOp)
    visitParenthesis:       abstract func (node: Parenthesis)
    visitLine:              abstract func (node: Line)
    
    visitReturn:            abstract func (node: Return)

    visitCast:              abstract func (node: Cast)
    visitComparison:        abstract func (node: Comparison)
    
    visitTernary:           abstract func (node: Ternary)

}
