import io/File
import Module
import ../frontend/[Token, AstBuilder]

Import: class {
    
    path: String
    module : Module = null
    isTight := false // tight imports include '.h', loose imports include '-fwd.h'
    token: Token
    
    init: func ~imp (=path, =token) {
        this path = this path replace('/', File separator)
    }
    
    setModule: func(=module) {}
    
    getModule: func -> Module {
        if(module == null && token module != null) {
            impPath = null, impElement = null : File
            path = null: String
            AstBuilder getRealImportPath(this, token module, token module params, path&, impPath&, impElement&)
            
            if(impPath != null) {
                module = AstBuilder cache get(impPath path)
            }
        }
        
        module
    }
    
    isTight: func -> Bool { isTight }
    setTight: func (=isTight) {}
    
}
