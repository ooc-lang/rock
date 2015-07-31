import UseDef

import ../frontend/[Token, BuildParams]
import tinker/Errors

Use: class {

    identifier: String
    useDef: UseDef { get set }
    token: Token

    init: func (=identifier, params: BuildParams, =token) {
        useDef = UseDef parse(identifier, params)
        if(!useDef) {
            params errorHandler onError(UseNotFound new(token, identifier))
        } else {
            useDef apply(params)
        }
    }

}

