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
        // If no value is provided for an element,
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

        element setType(instanceType)
        getMeta() addVariable(element)
    }

    setIncrement: func (=incrementOper, =incrementStep) {}
    
    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof(int)")
    }

    accept: func (visitor: Visitor) {
        visitor visitEnumDecl(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

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
