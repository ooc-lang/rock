import structs/HashMap
import ../io/TabbedWriter
import TypeDecl, Declaration, Visitor, Node, VariableAccess, Type, VariableDecl

EnumDecl: class extends TypeDecl {
    lastElementValue: Int = 0
    elements := HashMap<String, EnumElement> new()

    init: func ~enumDecl(.name, .token) {
        super(name, token)
    }

    addElement: func (element: EnumElement) {
        // If no value is provided, increment the last used
        // value and use that for this element.
        // TODO: support custom steps. Ex: *2, +1
        if(!element valueSet) {
            lastElementValue += 1
            element setValue(lastElementValue)
        } else {
            lastElementValue = element getValue()
        }

        element setType(instanceType)
        getMeta() addVariable(element)
    }
    
    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof(int)")
    }

    accept: func (visitor: Visitor) {
        visitor visitEnumDecl(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool {}

    resolveAccess: func (access: VariableAccess) {
        printf("Resolving access to %s in enum %s\n", access getName(), name)
        
        value := elements get(access name)
        if(value) {
            access suggest(value)
        }
    }
}

EnumElement: class extends VariableDecl {
    type: Type
    value: Int
    valueSet: Bool = false

    init: func ~enumElementDecl(.type, .name, .token) {
        super(type, name, token)
    }

    setValue: func (=value) { valueSet = true }
    getValue: func -> Int { value }

    setType: func (=type) {}
    getType: func -> Type { type }

    accept: func (visitor: Visitor) {}

    replace: func (oldie, kiddo: Node) -> Bool { false }
}
