import ../middle/Visitor
import ../io/TabbedWriter, io/[File, FileWriter]
import ../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    Line, BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use]

CGenerator: class extends Visitor {

    hw, cw, current: TabbedWriter

    outPath: String
    module: Module

    init: func (=outPath, =module) {
        File new(outPath) mkdirs()
        fileName := outPath append~char(File separator) + module simpleName
        printf("Writing to fileName %s\n", fileName)
        hw = TabbedWriter new(FileWriter new(fileName + ".h"))
        cw = TabbedWriter new(FileWriter new(fileName + ".c"))
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

        // write all includes
        current = hw
        for(inc in module includes) {
            visitInclude(inc)
        }
        
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
        if(!line inner class instanceof(ControlStatement))
            current app(';')
    }
    
    /** Write an add !!! */
    visitBinaryOp: func (op: BinaryOp) {
        op left accept(this)
        current app(" ") .app(OpType repr get(op type)) .app(" ")
        op right accept(this)
    }
    
    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        value : Char[128]
        sprintf(value, "%lld", lit value)
        current app(value as String)
    }
    
    /** Write a string literal */
    visitStringLiteral: func (str: StringLiteral) {
        current app('"') .app(str value) .app('"')
    }
    
    /** Write a char literal */
    visitCharLiteral: func (chr: CharLiteral) {
        current app('\'') .app(chr value) .app('\'')
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
    
    /** Write a conditional */
    writeConditional: func (name: String, cond: Conditional) {
        current app(name) .app(" (" )
        cond condition accept(this)
        current app(") {") .tab() .nl()
        for(line: Line in cond body) {
            line accept(this)
        }
        current untab() .nl() .app("}")
    }
    
    /** Write an if */
    visitIf: func (if1: If) {
        writeConditional("if", if1)
    }
    
    /** Write an else */
    visitElse: func (else1: Else) {
        writeConditional("else", else1)
    }
    
    /** Write a while */
    visitWhile: func (while1: While) {
        writeConditional("while", while1)
    }

    /** Write a foreach */
    visitForeach: func (foreach: Foreach) {
        if(!foreach collection class instanceof(RangeLiteral)) {
            Exception new(this, "Iterating over not a range but a " + foreach collection class name) throw()
        }
        range := foreach collection as RangeLiteral
        current app("for (")
        foreach variable accept(this)
        current app(" = ")
        range lower accept(this)
        current app("; ")
        foreach variable accept(this)
        current app(" < ")
        range upper accept(this)
        current app("; ")
        foreach variable accept(this)
        current app("++) {") .tab()
        for(line: Line in foreach body) {
            line accept(this)
        }
        current untab() .nl() .app("}")
        
    }
    
    /** Write a range literal */
    visitRangeLiteral: func (range: RangeLiteral) {
        Exception new(this, "Should write a Range Literal? wtf?") throw()
    }
    
    /** Write an include */
    visitInclude: func (inc: Include) {
        chevron := (inc mode == IncludeModes PATHY)
        current nl() .app("#include ") .app(chevron ? '<' : '"') .app(inc path) .app(".h") .app(chevron ? '>' : '"')
    }

}
