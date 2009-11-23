import ../middle/Visitor
import ../io/TabbedWriter, io/[File, FileWriter, Writer], AwesomeWriter
import ../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    Line, BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary]
    
import Skeleton, FunctionDeclWriter, ControlStatementWriter, ClassDeclWriter,
    ModuleWriter, CoverDeclWriter

CGenerator: class extends Skeleton {

    outPath: String
    module: Module

    init: func (=outPath, =module) {
        File new(outPath) mkdirs()
        modOutPath := module getOutPath("")
        fileName := outPath + File separator + modOutPath
        File new(fileName) parent() mkdirs()
        //printf("Writing to fileName '%s'", fileName)
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
        if(!line inner instanceOf(ControlStatement))
            current app(';')
    }
    
    /** Write a binary operation */
    visitBinaryOp: func (op: BinaryOp) {
        current app(op left). app(" "). app(op type toString()). app(" "). app(op right)
    }
    
    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        current app("%lld" format(lit value))
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
    visitVariableDecl: func (vDecl: VariableDecl) {
        current app(vDecl type). app(' '). app(vDecl name)
        if(vDecl expr)
            current app(" = "). app(vDecl expr)
    }
    
    /** Write a variable access */
    visitVariableAccess: func (varAcc: VariableAccess) {
        if(varAcc expr) {
            current app(varAcc expr). app('.')
        }
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
        CoverDeclWriter write(this, cDecl)
    }
    
    visitParenthesis: func (paren: Parenthesis) {
        current app('('). app(paren inner). app(')')
    }
    
    visitReturn: func (ret: Return) {
        current app("return")
        if(ret expr) current app(' '). app(ret expr)
    }
    
    visitCast: func (cast: Cast) {
        current app('('). app(cast type). app(") "). app(cast inner)
    }
    
    visitComparison: func (comp: Comparison) {
        current app(comp left). app(" "). app(comp compType toString()). app(" "). app(comp right)
    }
    
    visitTernary: func (tern: Ternary) {
        current app(tern condition). app(" ? "). app(tern ifTrue). app(" : "). app(tern ifFalse)
    }

}
