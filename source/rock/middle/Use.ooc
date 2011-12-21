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
            params errorHandler onError(UseNotFound new(this,
"Use not found in the ooc library path: %s
\nTo install ooc libraries, copy their directories to /usr/lib/ooc/
If you want to install libraries elsewhere, use the OOC_LIBS environment variable,
which is the path ooc will scan for .use files (in this case, %s.use)
For more informations, see http://docs.ooc-lang.org/libs.html
-------------------" format(identifier, identifier))
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

