import UseDef

import ../frontend/[Token, BuildParams]

Use: class {

    identifier: String
    useDef: UseDef = null
    
    init: func (=identifier, params: BuildParams, token: Token) {
        useDef = UseDef parse(identifier, params)
        if(useDef == null) {
            token throwError(
"Use not found in the ooc library path: %s
\nTo install ooc libraries, copy their directories to /usr/lib/ooc/
If you want to install libraries elsewhere, use the OOC_LIBS environment variable,
which is the path ooc will scan for .use files (in this case, %s.use)
For more informations, see http://docs.ooc-lang.org/libs.html
-------------------" format(identifier, identifier)
            )
        }
    }
    
    getUseDef: func -> UseDef {
        useDef
    }

}
