import structs/HashMap
import TypeDecl, Declaration, Visitor, Node, VariableAccess, Type

EnumDecl: class extends TypeDecl {
    lastElementValue: Int = 0
    elements := HashMap<String, EnumElementDecl> new()

    init: func ~enumDecl(=name, .token) {
        super(token)
        type = BaseType new(name, token)
    }

    addElement: func (element: EnumElementDecl) {
        // If no value is provided, increment the last used
        // value and use that for this element.
        if(!element valueSet) {
            lastElementValue += 1
            element setValue(lastElementValue)
        }
        else {
            lastElementValue = element getValue()
        }

        element setType(type)
        elements add(element name, element)
    }

    accept: func (visitor: Visitor) {}

    replace: func (oldie, kiddo: Node) -> Bool { false }

    resolveAccess: func (access: VariableAccess) {
        value := elements get(access name)
        if(value) {
            access suggest(value)
        }
    }
}

EnumElementDecl: class extends Declaration {
    type: Type
    name: String
    value: Int
    valueSet: Bool = false

    init: func ~enumElementDecl(=name, .token) {
        super(token)
    }

    setValue: func (=value) { valueSet = true }
    getValue: func -> Int { value }

    setType: func (=type) {}
    getType: func -> Type { type }

    accept: func (visitor: Visitor) { visitor visitEnumElementDecl(this) }

    replace: func (oldie, kiddo: Node) -> Bool { false }
}
