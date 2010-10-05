
import rock/middle/ast2/[Module, Node, FuncDecl, Access, Var, Scope, Type,
    Call, StringLit]

import structs/HashMap, io/FileWriter

CallBack: class {
    f: Func (Node)

    init: func (=f) {}
}

Backend: class {

    module: Module
    fw: FileWriter
    
    map := HashMap<Class, CallBack> new()

    init: func (=module) {
        fw = FileWriter new("out.c")
        
        put(FuncDecl, func(f: FuncDecl) {
            if(f isExtern) return
            
            fw write("void")
            fw write(" "). write(f name). write("() ")
            write(f body)
        })
        
        put(Call, func(c: Call) {
            fw write(c name). write("(")
            first := true
            c args each(|arg|
                if(!first) fw write(", ")
                write(arg)
            )
            fw write(")")
        })

        put(StringLit, func(c: StringLit) {
            fw write('"'). write(c value). write('"')
        })

        put(Scope, func(s: Scope) {
            fw write("{\n")
            s body each(|stat|
                write(stat)
                fw write(";\n")
            )
            fw write("}\n")
        })

        put(Var, func (v: Var) {
            write(v type)
            fw write(" "). write(v name)
            if(v expr) {
                fw write(" = ")
                write(v expr)
            }
        })
        
        put(BaseType, func (b: BaseType) {
            fw write(b name)
        })

        put(Access, func (a: Access) {
            fw write(a name)
        })
    }

    put: func (c: Class, f: Func (Node)) {
        map put(c, CallBack new(f))
    }

    write: func (n: Node) {
        cb := map get(n class)
        if(cb) {
            cb f(n)
        } else {
            ("Unknown node type " + n class name) printfln()
        }
    }

    generate: func {
        module functions each(|f|
            write(f)
        )
    }

}


