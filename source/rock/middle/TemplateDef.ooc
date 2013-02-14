
// sdk stuff
import structs/HashMap

// our stuff
import Declaration, Type, Node, Visitor

TemplateDef: class extends Declaration {
    
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

}
