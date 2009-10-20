import ../frontend/Token
import Node, Visitor

voidType := Type new("void")

Type: class extends Node {

    name: String
    
    init: func ~type (.name) { this(name, nullToken) }
    init: func ~typeWithName (=name, .token) { super(token) }

    accept: func (visitor: Visitor) { visitor visitType(this) }

}
