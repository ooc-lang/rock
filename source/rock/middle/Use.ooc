import UseDef

import ../frontend/[Token, BuildParams]
import tinker/Errors

Use: class {

    identifier: String
    useDef: UseDef { get set }
    token: Token

    init: func (=identifier, params: BuildParams, =token) {
        uDef := UseDef parse(identifier, params)
        if(!uDef) {
            params errorHandler onError(UseNotFound new(this, "Library not found: %s.use" format(identifier, identifier))
            )
        } else {
	    useDef = uDef
	    useDef apply(params)
	}
    }

}

UseNotFound: class extends Error {
    uze: Use

    init: func (=uze, .message) {
        super(uze token, message)
    }
}

