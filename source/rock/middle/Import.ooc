import Module

Import: class {
    
    path: String
    module : Module = null
    
    init: func (=path) {}
    
    setModule: func(=module) {}
    
    getModule: func -> Module {
        module
    }
    
}
