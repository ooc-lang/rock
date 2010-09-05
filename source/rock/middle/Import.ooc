import io/File
import Module
import ../frontend/[Token, AstBuilder]

Import: class {

    path: String
    module : Module = null
    isTight := false // tight imports include '.h', loose imports include '-fwd.h'
    token: Token

    init: func ~imp (=path, =token) {
        this path = this path replaceAll('/', File separator)
    }

    setModule: func(=module) {
        if(module != null) {
            module timesImported += 1
        }
    }

    getModule: func -> Module {
        if(module == null && token module != null) {
            (path, impPath, impElement) :=  AstBuilder getRealImportPath(this, token module, token module params)
            if(impPath != null) {
                setModule(AstBuilder cache get(impPath path))
            }
        }
        module
    }

    getPath: func -> String { path }

    isTight: func -> Bool { isTight }
    setTight: func (=isTight) {}

}
