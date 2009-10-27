import Node

Visitor: abstract class {
    
    // All a big hack. To avoid specific circular imports which are buggy atm.
    visitClassDecl:         abstract func (node: Node)
    visitCoverDecl:         abstract func (node: Node)
    visitFunctionDecl:      abstract func (node: Node)
    visitVariableDecl:      abstract func (node: Node)
    
    visitType:              abstract func (node: Node)
    
    visitModule:            abstract func (node: Node)
    
    visitIf:                abstract func (node: Node)
    visitElse:              abstract func (node: Node)
    visitWhile:             abstract func (node: Node)
    visitForeach:           abstract func (node: Node)
    
    visitRangeLiteral:      abstract func (node: Node)
    visitCharLiteral:       abstract func (node: Node)
    visitStringLiteral:     abstract func (node: Node)
    visitIntLiteral:        abstract func (node: Node)
    
    visitVariableAccess:    abstract func (node: Node)
    visitFunctionCall:      abstract func (node: Node)
    
    visitBinaryOp:          abstract func (node: Node)
    visitParenthesis:       abstract func (node: Node)
    visitLine:              abstract func (node: Node)

}
