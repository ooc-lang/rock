import Module
import ../frontend/Token

Import: class {
    
    path: String
    module : Module = null
    isTight := false // tight imports include '.h', loose imports include '-fwd.h'
    token: Token
    
    init: func ~imp (=path, =token) {}
    
    setModule: func(=module) {}
    
    getModule: func -> Module {
        module
    }
    
    isTight: func -> Bool { isTight }
    setTight: func (=isTight) {}
    
}
