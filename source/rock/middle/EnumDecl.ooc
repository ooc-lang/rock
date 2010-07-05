import structs/HashMap
import ../io/TabbedWriter
import TypeDecl, Declaration, Visitor, Node, VariableAccess, Type, VariableDecl

EnumDecl: class extends TypeDecl {
    lastElementValue: Int = 0
    elements := HashMap<String, EnumElement> new()
    incrementOper: Char = '+'
    incrementStep: Int = 1

    init: func ~enumDecl(.name, .token) {
        super(name, token)
    }

    addElement: func (element: EnumElement) {
        if(isExtern()) {
            if(!element isExtern()) {
                // Provide a default extern name if none is provided
                element setExternName(element getName())
            }
        } else {
            // If no value is provided for a non-extern element,
            // calculate it by incrementing the last used value.
            if(!element valueSet) {
                if(incrementOper == '+') {
                    lastElementValue += incrementStep
                } else if(incrementOper == '*') {
                    lastElementValue *= incrementStep
                }

                element setValue(lastElementValue)
            } else {
                lastElementValue = element getValue()
            }
        }

        element setType(instanceType)
        getMeta() addVariable(element)
    }

    setIncrement: func (=incrementOper, =incrementStep) {}

    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof("). app(isExtern() ? name : "int"). app(")")
    }

    accept: func (visitor: Visitor) {
        visitor visitEnumDecl(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }
}

EnumElement: class extends VariableDecl {
    doc := null
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
