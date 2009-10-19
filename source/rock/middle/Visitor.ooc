import Node

Visitor: abstract class {
    
    // All a big hack. To avoid specific circular imports which are buggy atm.
    visitVariableAccess:    abstract func (node: Node)
    visitVariableDecl:      abstract func (node: Node)
    visitModule:            abstract func (node: Node)
    visitIntLiteral:        abstract func (node: Node)
    visitFunctionCall:      abstract func (node: Node)
    visitFunctionDecl:      abstract func (node: Node)
    visitType:              abstract func (node: Node)
    visitAdd:               abstract func (node: Node)
    visitLine:              abstract func (node: Node)

}
