
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
    FlowControl, InterfaceDecl, Version, Block]

import Skeleton, FunctionDeclWriter, ControlStatementWriter,
    ClassDeclWriter, ModuleWriter, CoverDeclWriter, FunctionCallWriter,
    CastWriter, InterfaceDeclWriter, VersionWriter


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
        type write(current, null)
    }

    /** Write a binary operation */
    visitBinaryOp: func (op: BinaryOp) {
        
        // when assigning to a member function (e.g. for hotswapping),
        // you want to change the class field, not just the function name
        isFunc := op type == OpTypes ass &&
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
        } else if(op type == OpTypes ass) {
            if(op left  getType() isPointer() ||
               op right getType() isPointer()) {
                current app("(void*) ")
            } else if(op right getType() inheritsFrom(op left getType())) {
                current app('('). app(op left getType()). app(") ")
            }
        }
        
        current app(op right)
        
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
       
        vDecl getType() write(current, vDecl getFullName())
        if(vDecl expr)
            current app(" = "). app(vDecl expr)
    }

    /** Write a variable access */
    visitVariableAccess: func (varAcc: VariableAccess) {
        if(varAcc ref == null) {
            Exception new(This, "Trying to write unresolved variable access %s" format(varAcc getName())) throw()
        }

        if(varAcc ref instanceOf(VariableDecl)) {
            vDecl := varAcc ref as VariableDecl
            if(varAcc isMember()) {
                casted := false
                if(vDecl owner != varAcc expr getType() getRef()) {
                    casted = true
                    current app("(("). app(vDecl owner underName()). app("*) ")
                }

                current app(varAcc expr)

                if(casted) current app(")")

                refLevel := 0
                
                
                if(varAcc expr getType() getRef() instanceOf(ClassDecl)) {
                    refLevel += 1
                }
                
                current app(match (refLevel) {
                    case 0 => "."
                    case 1 => "->"
                    case   => varAcc token throwError("This is too much reference %d! Can't write it." format(refLevel)); ""
                })
            }
            paren := false
            if(varAcc getRef() getType() instanceOf(ReferenceType)) {
                current app("(*")
                paren = true
            }
            
            if(vDecl isExternWithName()) {
                current app(vDecl getExternName())
            } else {
                current app(vDecl getFullName())
            }
            
            if(paren) current app(')')
        } else if(varAcc ref instanceOf(TypeDecl)) {
            tDecl := varAcc ref as TypeDecl
            current app(tDecl getFullName()). app("_class()")
        } else if(varAcc ref instanceOf(FunctionDecl)) {
            fDecl := varAcc ref as FunctionDecl
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
    visitBlock: func (b: Block) {
        current nl(). app('{'). tab()
        for(stmt in b getBody()) {
            writeLine(stmt)
        }
        current untab(). nl(). app('}')
    }

    /** Write a range literal */
    visitRangeLiteral: func (range: RangeLiteral) {
        Exception new(This, "Should write a Range Literal? wtf?") throw()
    }

    visitBoolLiteral: func (b: BoolLiteral) {
        current app(b value ? "true" : "false")
    }

    /** Write an interface declaration */
    visitInterfaceDecl: func (iDecl: InterfaceDecl) {
        InterfaceDeclWriter write(this, iDecl)
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
        current app(comp left). app(" "). app(comp compType toString()). app(" ")
        if(!comp right getType() equals(comp left getType())) {
            current app('('). app (comp left getType()). app(") ") 
        }
        current app(comp right)
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
        if(node expr instanceOf(VariableAccess)) {
            varAcc := node expr as VariableAccess
            if(varAcc getType() isGeneric()) {
                // generic variables are already pointers =)
                current app(node expr); return
            }
        }
        
        if(node expr instanceOf(Dereference)) {
            current app(node expr as Dereference expr)
			return;
		}
        
        current app("&("). app(node expr). app(")")
    }

    visitDereference: func (node: Dereference) {
        current app("(*("). app(node expr). app("))")
    }

    visitCommaSequence: func (node: CommaSequence) {
        current app("(")
        isFirst := true
        for(statement in node getBody()) {
            if(isFirst) isFirst = false
            else        current app(", ")
            current app(statement)
        }
        current app(")")
    }
    
    visitVersionBlock: func (node: VersionBlock) {
        VersionWriter writeStart(this, node getSpec())
        for(statement in node getBody()) {
            writeLine(statement)
        }
        VersionWriter writeEnd(this)
    }

}
