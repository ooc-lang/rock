import ../middle/Visitor
import ../io/TabbedWriter, io/[File, FileWriter, Writer], AwesomeWriter
import ../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    Line, BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis]
    
import Skeleton, FunctionDeclWriter, ControlStatementWriter, ClassDeclWriter,
    ModuleWriter

CGenerator: class extends Skeleton {

    outPath: String
    module: Module

    init: func (=outPath, =module) {
        File new(outPath) mkdirs()
        fileName := outPath + File separator + module fullName
        File new(fileName) parent() mkdirs()
        printf("Writing to fileName %s\n", fileName)
        hw = AwesomeWriter new(this, FileWriter new(fileName + ".h"))
        fw = AwesomeWriter new(this, FileWriter new(fileName + "-fwd.h"))
        cw = AwesomeWriter new(this, FileWriter new(fileName + ".c"))
    }
    
    close: func {
        hw nl(). close()
        fw nl(). close()
        cw nl(). close()
    }
    
    /** Write the whole module */
    write: func {
        visitModule(module)
    }
    
    /** Write a module */
    visitModule: func(module: Module) {
        ModuleWriter write(this, module)
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
        type write(current)
    }
    
    /** Write a line */
    visitLine: func (line: Line) {
        current nl(). app(line inner)
        if(!line inner class instanceof(ControlStatement))
            current app(';')
    }
    
    /** Write a binary operation */
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
    
    /** Write a class declaration */
    visitClassDecl: func (cDecl: ClassDecl) {
        ClassDeclWriter write(this, cDecl)
    }
    
    /** Write a cover declaration */
    visitCoverDecl: func (cDecl: CoverDecl) {
        
    }
    
    visitParenthesis: func (paren: Parenthesis) {
        current app('('). app(paren inner). app(')')
    }

}
