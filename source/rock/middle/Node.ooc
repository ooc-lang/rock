import Visitor
import ../frontend/Token
import tinker/Response

Node: abstract class {

    token: Token
    
    init: func(=token) {}
    
    accept: abstract func (visitor: Visitor)
    
    toString: func -> String { class name }
    
    resolve: func -> Response { Responses OK }

}
