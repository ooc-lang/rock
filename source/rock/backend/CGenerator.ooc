import ../middle/Visitor
import ../io/TabbedWriter, io/[File, FileWriter, Writer], AwesomeWriter
import ../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    Line, BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node]
    
import Skeleton, FunctionDeclWriter, ControlStatementWriter, ClassDeclWriter

CGenerator: class extends Skeleton {

    outPath: String
    module: Module

    init: func (=outPath, =module) {
        File new(outPath) mkdirs()
        fileName := outPath append~char(File separator) + module simpleName
        printf("Writing to fileName %s\n", fileName)
        hw = AwesomeWriter new(this, FileWriter new(fileName + ".h"))
        cw = AwesomeWriter new(this, FileWriter new(fileName + ".c"))
    }
    
    close: func {
        hw nl(). close()
        cw nl(). close()
    }
    
    /** Write the whole module */
    write: func {
        visitModule(module)
    }
    
    /** Write a module */
    visitModule: func(module: Module) {
        hw app("/* "). app(module fullName). app(" header file, generated with rock, the ooc compiler written in ooc */"). nl()
        cw app("/* "). app(module fullName). app(" source file, generated with rock, the ooc compiler written in ooc */"). nl()

        hName := "__"+ module fullName clone() replace('/', '_') replace('-', '_') + "__"

        // header
        current = hw
        current nl(). app("#ifndef "). app(hName)
        current nl(). app("#define "). app(hName). nl()

        // write all includes
        for(inc in module includes) {
            visitInclude(inc)
        }
        
        // source
        current = cw
        // write include to the module's. h file
        current nl(). app("#include \""). app(module simpleName). app(".h\""). nl()
        
        // write all types
        for(tDecl: TypeDecl in module types) {
            printf("Writing type %s\n", tDecl name)
            tDecl accept(this)
        }
        
        // write all functions
        for(fDecl: FunctionDecl in module functions) {
            printf("Writing function %s\n", fDecl name)
            visitFunctionDecl(fDecl)
        }
        
        // header end
        current = hw
        current nl(). nl(). app("#endif // "). app(hName)
    }
    
    /** Write a function declaration */
    visitFunctionDecl: func (fDecl: FunctionDecl) { FunctionDeclWriter write(this, fDecl) }
    
    /** Write a function call */
    visitFunctionCall: func (function: FunctionCall) {
        current app(function name). app('(')
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
        current nl(). app(line inner)
        if(!line inner class instanceof(ControlStatement))
            current app(';')
    }
    
    /** Write an add !!! */
    visitBinaryOp: func (op: BinaryOp) {
        current app(op left). app(" "). app(op type toString()). app(" "). app(op right)
    }
    
    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        value : Char[128]
        sprintf(value, "%lld", lit value)
        current app(value as String)
    }
    
    /** Write a string literal */
    visitStringLiteral: func (str: StringLiteral) {
        current app('"'). app(str value). app('"')
    }
    
    /** Write a char literal */
    visitCharLiteral: func (chr: CharLiteral) {
        current app('\''). app(chr value). app('\'')
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
                current app(" = "). app(atom expr)
            }
        }
    }
    
    /** Write a variable access */
    visitVariableAccess: func (varAcc: VariableAccess) {
        current app(varAcc name)
    }
    
    /** Control statements */
    visitIf: func (if1: If) {
        ControlStatementWriter write(this, if1)
    }
    visitElse: func (else1: Else) {
        ControlStatementWriter write(this, else1)
    }
    visitWhile: func (while1: While) {
        ControlStatementWriter write(this, while1)
    }
    visitForeach: func (foreach: Foreach) {
        ControlStatementWriter write(this, foreach)
    }
    
    /** Write a range literal */
    visitRangeLiteral: func (range: RangeLiteral) {
        Exception new(This, "Should write a Range Literal? wtf?") throw()
    }
    
    /** Write an include */
    visitInclude: func (inc: Include) {
        chevron := (inc mode == IncludeModes PATHY)
        current nl(). app("#include "). app(chevron ? '<' : '"').
            app(inc path). app(".h"). 
        app(chevron ? '>' : '"')
    }
    
    /** Write a class declaration */
    visitClassDecl: func (cDecl: ClassDecl) {
        ClassDeclWriter write(this, cDecl)
    }
    
    /** Write a cover declaration */
    visitCoverDecl: func (cDecl: CoverDecl) {
        
    }


}
