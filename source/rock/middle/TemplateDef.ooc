
// sdk stuff
import structs/[ArrayList, HashMap]

// our stuff
import Declaration, Type, Node, Visitor, VariableDecl

TemplateDef: class extends Declaration {

    typeArgs := ArrayList<VariableDecl> new()
    
    init: func (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        // no-op
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        Exception new("Can't replace in %s" format(This name)) throw()
        false
    }

    clone: func -> This {
        Exception new("Can't clone %s" format(This name)) throw()
        null
    }

    getType: func -> Type {
        Exception new("Template defs don't have types") throw()
        null
    }

    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        typeArgs add(typeArg)
        true
    }

    toString: func -> String {
        sb := Buffer new()
        sb append("<")
        for ((i, typeArg) in typeArgs) {
            if (i > 0) sb append(", ")
            sb append(typeArg ? typeArg toString() : "(null)")
        }
        sb append(">")
        sb toString()
    }

}
