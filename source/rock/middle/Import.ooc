import Module

Import: class {
    
    path: String
    module : Module = null
    isTight := false // tight imports include '.h', loose imports include '-fwd.h'
    
    init: func (=path) {}
    
    setModule: func(=module) {}
    
    getModule: func -> Module {
        module
    }
    
    isTight: func -> Bool { isTight }
    setTight: func (=isTight) {}
    
}
