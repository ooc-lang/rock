import Visitor
import ../frontend/Token

Node: abstract class {

    token: Token
    
    init: func(=token) {}
    
    accept: abstract func (visitor: Visitor)

}
