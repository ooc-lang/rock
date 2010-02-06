
import structs/List

import ../../middle/Visitor
import ../../io/TabbedWriter, io/[File, FileWriter, Writer], AwesomeWriter

import ../../frontend/BuildParams

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, FloatLiteral, CharLiteral, StringLiteral,
    RangeLiteral, NullLiteral, VariableDecl, If, Else, While, Foreach,
    Conditional, ControlStatement, VariableAccess, Include, Import,
    Use, TypeDecl, ClassDecl, CoverDecl, Node, Parenthesis, Return,
    Cast, Comparison, Ternary, BoolLiteral, Argument, Statement,
    AddressOf, Dereference, CommaSequence, UnaryOp, ArrayAccess, Match,
    FlowControl]

import Skeleton, FunctionDeclWriter, ControlStatementWriter, ClassDeclWriter,
    ModuleWriter, CoverDeclWriter, FunctionCallWriter, CastWriter


CGenerator: class extends Skeleton {

    params: BuildParams
    module: Module

    init: func (=params, =module) {
        outPath := params getOutputPath(module, "")
        File new(outPath) parent() mkdirs()
        hw = AwesomeWriter new(this, FileWriter new(outPath + ".h"))
        fw = AwesomeWriter new(this, FileWriter new(outPath + "-fwd.h"))
        cw = AwesomeWriter new(this, FileWriter new(outPath + ".c"))
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
        
        // when assigning to a member function (e.g. for hotswapping),
        // you want to change the class field, not just the function name
        isFunc := op isAssign() &&
                  op left instanceOf(VariableAccess) &&
                  op left as VariableAccess ref instanceOf(FunctionDecl) &&
                  op left as VariableAccess ref as FunctionDecl getOwner() != null
                  
        if(isFunc) {
            fDecl := op left as VariableAccess ref as FunctionDecl
            current app(fDecl owner as TypeDecl name). app("_class()->"). app(fDecl name)
        } else {
            current app(op left)
        }
        
        current app(" "). app(op type toString()). app(" ")
        
        if(isFunc) {
            current app("(void*) ")
        }
        
        if(op right getType() inheritsFrom(op left getType())) {
            current app("(("). app(op left getType()). app(") ") .app(op right). app(")")
        } else {
            current app(op right)
        }
        
    }

    /** Write a unary operation */
    visitUnaryOp: func (op: UnaryOp) {
        current app(op type toString()). app(op inner)
    }

    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        current app("%lld" format(lit value))
    }

    /** Write a float literal */
    visitFloatLiteral: func (lit: FloatLiteral) {
        current app("%f" format(lit value))
    }

    /** Write a string literal */
    visitStringLiteral: func (str: StringLiteral) {
        current app('"'). app(str value). app('"')
    }

    /** Write a char literal */
    visitCharLiteral: func (chr: CharLiteral) {
        current app('\''). app(chr value). app('\'')
    }

    /** Write a null literal! */
    visitNullLiteral: func (lit: NullLiteral) {
        current app("NULL")
    }

    /** Write a variable declaration */
    visitVariableDecl: func (vDecl: VariableDecl) {
        if(vDecl isExtern()) return
        current app(vDecl getType()). app(' '). app(vDecl name)
        if(vDecl expr)
            current app(" = "). app(vDecl expr)
    }

    /** Write a variable access */
    visitVariableAccess: func (varAcc: VariableAccess) {
        if(varAcc ref == null) {
            Exception new(This, "Trying to write unresolved variable access %s" format(varAcc toString())) throw()
        }

        if(varAcc ref instanceOf(VariableDecl)) {
            vDecl := varAcc ref as VariableDecl
            if(vDecl isExternWithName()) {
                current app(vDecl getExternName())
            } else {
                if(varAcc expr) {
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
            }
        } else if(varAcc ref instanceOf(TypeDecl)) {
            tDecl := varAcc ref as TypeDecl
            // FIXME: use mangled name here later
            current app(tDecl name). app("_class()")
        } else if(varAcc ref instanceOf(FunctionDecl)) {
            fDecl := varAcc ref as FunctionDecl
            // FIXME: use mangled name here later
            FunctionDeclWriter writeFullName(this, fDecl)
        }
    }

    /** Write an array access */
    visitArrayAccess: func (arrAcc: ArrayAccess) {
        current app(arrAcc getArray()). app('['). app(arrAcc getIndex()). app(']')
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
    visitMatch: func (mat: Match) {
        ControlStatementWriter write(this, mat)
    }
    visitFlowControl: func (fc: FlowControl) {
        current app(fc getAction() toString())
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

    visitCommaSequence: func (node: CommaSequence) {
        current app("(")
        isFirst := true
        for(statement: Statement in node getBody()) {
            if(isFirst) isFirst = false
            else        current app(", ")
            current app(statement)
        }
        current app(")")
    }

}
