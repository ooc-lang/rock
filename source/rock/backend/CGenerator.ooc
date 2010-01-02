import ../middle/Visitor
import ../io/TabbedWriter, io/[File, FileWriter, Writer], AwesomeWriter
import ../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference]
    
import Skeleton, FunctionDeclWriter, ControlStatementWriter, ClassDeclWriter,
    ModuleWriter, CoverDeclWriter, FunctionCallWriter, CastWriter

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
    visitFunctionCall: func (fCall: FunctionCall) { FunctionCallWriter write(this, fCall) }

    /** Write a type */
    visitType: func (type: Type) {
        type write(current)
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
        if(varAcc ref == null) {
            Exception new(This, "Trying to write unresolved variable access %s" format(varAcc toString())) throw()
        }
        
        if(varAcc ref instanceOf(VariableDecl)) {
            if(varAcc expr) {
                vDecl := varAcc ref as VariableDecl
                casted := false
                if(vDecl owner != varAcc expr getType() getRef()) {
                    casted = true
                    current app("(("). app(vDecl owner underName()). app("*) ")
                }
                
                current app(varAcc expr)
                
                if(casted) current app(")")
                
                if(varAcc expr getType() getRef() instanceOf(ClassDecl)) {
                    current app("->")
                } else {
                    current app('.')
                }
            }
            current app(varAcc name)
        } else if(varAcc ref instanceOf(TypeDecl)) {
            typeDecl : TypeDecl = varAcc ref
            //printf("()() Writing variable access to type %s\n", typeDecl toString())
            current app(typeDecl name). app("_class()")
        }
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

    visitBoolLiteral: func (b: BoolLiteral) {
        current app(b value ? "true" : "false")
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
        CastWriter write(this, cast)
    }
    
    visitComparison: func (comp: Comparison) {
        current app(comp left). app(" "). app(comp compType toString()). app(" "). app(comp right)
    }
    
    visitTernary: func (tern: Ternary) {
        current app(tern condition). app(" ? "). app(tern ifTrue). app(" : "). app(tern ifFalse)
    }
    
    visitVarArg: func (varArg: VarArg) {
        // note: this is a hack to support C-style varargs function definitions
        // in the future, this will be half-deprecated to support varargs
        // with ArrayLists of Value<T>
        current app("...")
    }
    
    visitAddressOf: func (node: AddressOf) {
        current app("&("). app(node expr). app(")")
    }
    
    visitDereference: func (node: Dereference) {
        current app("*("). app(node expr). app(")")
    }

}
