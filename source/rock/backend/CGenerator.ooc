import ../middle/Visitor
import ../io/TabbedWriter, io/File
import ../middle/[Module, FunctionDecl, FunctionCall, Expression,
    Type, Line, Add, IntLiteral, VariableDecl, VariableAccess]

CGenerator: class extends Visitor {

    hw, cw, current: TabbedWriter

    outPath: String
    module: Module

    init: func (=outPath, =module) {
        File new(outPath) mkdirs()
        fileName := outPath append~char(File separator) + module simpleName
        printf("Writing to fileName %s\n", fileName)
        hw = TabbedWriter new(fopen(fileName + ".h", "w"))
        cw = TabbedWriter new(fopen(fileName + ".c", "w"))
    }
    
    close: func {
        hw close()
        cw close()
    }
    
    /** Write the whole module */
    write: func {
        visitModule(module)
    }
    
    /** Write a module */
    visitModule: func(module: Module) {
        hw app("/* ") .app(module fullName) .app(" header file, generated with rock, the ooc compiler in ooc */") .nl()
        cw app("/* ") .app(module fullName) .app(" source file, generated with rock, the ooc compiler in ooc */") .nl()
        
        // write all functions
        for(fName in module functions keys) {
            visitFunctionDecl(module functions get(fName))
        }
    }
    
    /** Write a function prototype */
    writeFunctionPrototype: func (function: FunctionDecl) {
        visitType(function returnType)
        current app(' ') .app(function name) .app('(')
        current app(')')
    }
    
    /** Write a function declaration */
    visitFunctionDecl: func (function: FunctionDecl) {
        // header
        current = hw
        current nl()
        writeFunctionPrototype(function)
        current app(';')
        
        // source
        current = cw
        current nl()
        writeFunctionPrototype(function)
        current app(" {") .tab()
        for(line in function body) {
            visitLine(line)
        }
        current untab() .nl() .app("}")
    }
    
    /** Write a function call */
    visitFunctionCall: func (function: FunctionCall) {
        current app(function name) .app('(')
        isFirst := true
        for(arg: Expression in function args) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            arg accept(this)
        }
        current app(')')
    }

    /** Write a type */
    visitType: func (type: Type) {
        current app(type name)
    }
    
    /** Write a line */
    visitLine: func (line: Line) {
        current nl()
        line inner accept(this)
        current app(';')
    }
    
    /** Write an add !!! */
    visitAdd: func (add: Add) {
        add left accept(this)
        current app(" + ")
        add right accept(this)
    }
    
    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        value : Char[128]
        sprintf(value, "%lld", lit value)
        current app(value as String)
    }
    
    /** Write a variable declaration */
    visitVariableDecl: func (varDecl: VariableDecl) {
        visitType(varDecl type)
        isFirst := true
        for(atom: Atom in varDecl atoms) {
            if(isFirst) {
                isFirst = false 
                current app(' ')
            } else {
                current app(", ")
            }
            current app(atom name)
            if(atom expr) {
                current app(" = ")
                atom expr accept(this)
            }
        }
    }
    
    /** Write a variable access */
    visitVariableAccess: func (varAcc: VariableAccess) {
        current app(varAcc name)
    }

}
