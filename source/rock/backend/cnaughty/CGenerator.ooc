
// sdk
import structs/List

// visitor
import rock/middle/Visitor
import rock/middle/tinker/Errors

// i/o
import rock/io/[CachedFileWriter, TabbedWriter], io/[File, FileWriter, Writer], AwesomeWriter

// front-end
import rock/frontend/[BuildParams, Token]

// middle-end
import rock/middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, FloatLiteral, CharLiteral, StringLiteral,
    RangeLiteral, NullLiteral, VariableDecl, If, Else, While, Foreach,
    Conditional, ControlStatement, VariableAccess, Include, Import,
    Use, TypeDecl, ClassDecl, CoverDecl, Node, Parenthesis, Return,
    Cast, Comparison, Ternary, BoolLiteral, Argument, Statement,
    AddressOf, Dereference, CommaSequence, UnaryOp, ArrayAccess, Match,
    FlowControl, InterfaceDecl, Version, Block, EnumDecl, ArrayLiteral,
    ArrayCreation, StructLiteral, FuncType]

// backend
import Skeleton, FunctionDeclWriter, ControlStatementWriter,
    ClassDeclWriter, ModuleWriter, CoverDeclWriter, FunctionCallWriter,
    CastWriter, InterfaceDeclWriter, VersionWriter, AccessWriter,
    VariableAccessChecker

/**
 * Generate .c/.h/-fwd.h files from the AST of an ooc module
 *
 * The two .h files are useful to work around some limitations in
 * C's inclusion mechanism, especially concerning forward declarations,
 * since ooc allows declarations in almost any order, but C doesn't.
 */
CGenerator: class extends Skeleton {

    init: func ~cgenerator (=params, =module) {

        hOutPath := match (params libcache) {
            case true =>
                File new(params libcachePath, module getPath(""))
            case false =>
                File new(params outPath, module getPath(""))
        }
        hOutPath parent mkdirs()

        hw = _makeWriter(hOutPath path + ".h")
        fw = _makeWriter(hOutPath path + "-fwd.h")

        cOutPath := File new(params outPath, module getPath(".c"))
        cOutPath parent mkdirs()
        cw = _makeWriter(cOutPath path)
    }

    _makeWriter: func (path: String) -> AwesomeWriter {
        AwesomeWriter new(this, CachedFileWriter new(path))
    }

    /** Write the whole module, return true if files were modified on-disk */
    write: func -> Bool {

        visitModule(module)

        hw nl(); fw nl(); cw nl()

        written := hw stream as CachedFileWriter flushAndClose()
        written |= fw stream as CachedFileWriter flushAndClose()
        written |= cw stream as CachedFileWriter flushAndClose()
        written

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

    visitTypeAccess: func (typeAccess: TypeAccess) {
        ref := typeAccess getRef()

        match ref {
            case tDecl: TypeDecl =>
                if (typeAccess inner pointerLevel() > 0) {
                    current app("lang_types__Pointer_class()")
                } else {
                    current app(tDecl underName()). app("_class()")
                }
            case vDecl: VariableDecl =>
                // TODO: fix namespaced type accesses?
                // TODO: figure out if last parameter needs to be adjusted sometimes
                AccessWriter writeVariableDeclAccess(this, vDecl, false,
                    null, typeAccess token, true)
            case =>
                message := "Unsupported TypeAccess ref type for %s: %s" \
                format(typeAccess toString(), ref class name)
                params errorHandler onError(InternalError new(typeAccess token, message))
        }
    }

    /** Write a binary operation */
    visitBinaryOp: func (op: BinaryOp) {

        // when assigning to an array, use Array_set rather than assigning to _get
        isArray := op type == OpType ass &&
                   op left instanceOf?(ArrayAccess) &&
                   op left as ArrayAccess getArray() getType() instanceOf?(ArrayType) &&
                   op left as ArrayAccess getArray() getType() as ArrayType expr == null

        if(isArray) {
            arrAcc := op left as ArrayAccess
            type := arrAcc getArray() getType() as ArrayType
            current app("_lang_array__Array_set("). app(arrAcc getArray()).
                    app(", "). app(arrAcc indices[0]).
                    app(", "). app(type inner).
                    app(", "). app(op right). app(")")
            return
        }

        // when assigning to a member function (e.g. for hotswapping),
        // you want to change the class field, not just the function name
        isFunc := op type == OpType ass &&
                  op left instanceOf?(VariableAccess) &&
                  op left as VariableAccess ref instanceOf?(FunctionDecl) &&
                  op left as VariableAccess ref as FunctionDecl getOwner() != null

        if(isFunc) {
            fDecl := op left as VariableAccess ref as FunctionDecl
            current app(fDecl owner as TypeDecl getFullName()). app("_class()->"). app(fDecl name)
        } else {
            current app(op left)
        }

        current app(" "). app(op repr()). app(" ")


        if(!isFunc && op type == OpType ass) {
            leftType  := op left  getType()
            while(leftType  instanceOf?(ReferenceType)) { leftType  = leftType  as ReferenceType inner }
            rightType := op right getType()
            while(rightType instanceOf?(ReferenceType)) { rightType = rightType as ReferenceType inner }

            if(leftType  isPointer() ||
               rightType isPointer()) {
                current app("(void*) ")
            } else if(rightType inheritsFrom?(leftType)) {
                current app('('). app(leftType). app(") ")
            }
        }

        current app(op right)

    }

    /** Write a unary operation */
    visitUnaryOp: func (op: UnaryOp) {
        current app(op repr()). app(op inner)
    }

    /** Write an int literal */
    visitIntLiteral: func (lit: IntLiteral) {
        current app(lit toString())
    }

    /** Write a float literal */
    visitFloatLiteral: func (lit: FloatLiteral) {
        current app(lit toString())
    }

    /** Write a string literal */
    visitStringLiteral: func (str: StringLiteral) {
        writeStringLiteral(str value, str raw?)
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
        if(vDecl isExtern() && !vDecl isProto()) {
            return
        }

        if(vDecl isStatic()) {
            current app("static ")
        }
        vDecl getType() write(current, vDecl getFullName())
        if(vDecl expr && !vDecl isArg)
            current app(" = "). app(vDecl expr)
    }

    visitEnumDecl: func (eDecl: EnumDecl) {
        // we already wrote the forward decl somewhere else
    }

    /** Write a variable access */
    visitVariableAccess: func(varAcc: VariableAccess) { visitVariableAccess ~refAddr(varAcc, true)}

    visitVariableAccess: func ~refAddr(varAcc: VariableAccess, writeReferenceAddrOf: Bool) {
        if(varAcc ref == null) {
            Exception new(This, "Trying to write unresolved variable access %s" format(varAcc getName())) throw()
        }

        VariableAccessChecker check(params, varAcc)

        match (varAcc ref) {
            case element: EnumElement =>
                if(element isExtern()) {
                    current app(element getExternName())
                } else {
                    current app(element getValue() toString())
                }

            case vDecl: VariableDecl =>
                AccessWriter writeVariableDeclAccess(this, vDecl, varAcc isMember(),
                    varAcc expr, varAcc token, writeReferenceAddrOf)

            case tDecl: TypeDecl =>
                while(tDecl instanceOf?(CoverDecl) && tDecl as CoverDecl isAddon()) {
                    tDecl = tDecl as CoverDecl getBase() getNonMeta()
                }
                current app(tDecl getFullName()). app("_class()")

            case fDecl: FunctionDecl =>
                FunctionDeclWriter writeFullName(this, fDecl)

            case fType: FuncType =>
                // Yes, we need to write function types too ;D
                current app("lang_types__Closure_class()")
        }
    }

    /** Write an array access */
    visitArrayAccess: func (arrAcc: ArrayAccess) {
        arrType := arrAcc getArray() getType()
        if(arrType instanceOf?(ArrayType) && arrType as ArrayType expr == null) {
            inner := arrType as ArrayType inner
            current app("_lang_array__Array_get("). app(arrAcc getArray()). app(", "). app(arrAcc indices[0]). app(", "). app(inner). app(")")
        } else {
            current app(arrAcc getArray()). app('['). app(arrAcc indices[0]). app(']')
        }
    }

    visitStructLiteral: func (sl: StructLiteral) {
        if(!sl getType() instanceOf?(AnonymousStructType)) {
            current app('('). app(sl getType()). app(") ")
        }
        current app("{ "). tab()

        isVarArgs := sl getType() getName() == "VarArgs"
        i := 0
        for(element in sl elements) {
            if(i > 0) current app(", ")
            current nl()
            if(isVarArgs && i == 0) current app("(void*) ")
            current app(element)
            i += 1
        }
        current untab(). nl(). app("}")
    }

    visitArrayLiteral: func (arrLit: ArrayLiteral) {
        type := arrLit getType()
        if(!type instanceOf?(PointerType)) Exception new(This, "Array literal type %s isn't a PointerType but a %s, wtf?" format(arrLit toString(), type toString())) throw()

        current app("(")
        if(type as PointerType inner instanceOf?(ArrayType)) {
            //Nested array, sub-array is always of Array type
            current app("_lang_array__Array")
        } else {
            current app(type as PointerType inner)
        }
        current app("[]) { ")

        isFirst := true
        for(element in arrLit elements) {
            if(!isFirst) current app(", ")
            current app(element)
            isFirst = false
        }
        current app(" }")
    }

    visitArrayCreation: func (node: ArrayCreation) {
        writeArrayCreation(node arrayType, node expr, node generateTempName("arrayCrea"), !node literal?)
    }

    writeArrayCreation: func (arrayType: ArrayType, expr: Expression, name: String, writeForLoop?: Bool) {
        current app("_lang_array__Array_new(")
        if(arrayType inner instanceOf?(ArrayType)) {
            // otherwise, something like _lang_types__Bool[rows] is written
            // and that's the size of a pointer for C - which is wrong.
            // Array is larger than a pointer, it's a struct with several
            // members, see lang/array.h
            current app("_lang_array__Array")
        } else {
            arrayType inner write(current, null)
        }
        if(arrayType expr){
            current app(", "). app(arrayType expr). app(")")
        } else {
            current app(", "). app("0"). app(")")
        }

        if(writeForLoop? && arrayType inner instanceOf?(ArrayType)) {
            current app(';'). nl(). app("{"). tab(). nl(). app("int "). app(name). app("__i;"). nl().
                    app("for("). app(name). app("__i = 0; ").
                    app(name). app("__i < "). app(arrayType expr). app("; ").
                    app(name). app("__i++) { "). tab(). nl()

            current app("_lang_array__Array "). app(name). app("_sub = ")
            writeArrayCreation(arrayType inner as ArrayType, null, name + "_sub", true)

            current app(";"). nl(). app("_lang_array__Array_set(")
            if(expr) {
                current app(expr)
            } else {
                current app(name)
            }

            current app(", "). app(name). app("__i, ").
                    app(arrayType inner as ArrayType exprLessClone()). app(", "). app(name). app("_sub);").
                    untab(). nl(). app("}"). untab(). nl(). app("}")
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
        if(ret label) {
            // oh, it's a return-goto (ie we're in an inlined block)
            current app("goto "). app(ret label)
        } else {
            current app("return")
            if(ret expr) current app(' '). app(ret expr)
        }
    }

    visitCast: func (cast: Cast) {
        CastWriter write(this, cast)
    }

    visitComparison: func (comp: Comparison) {
        current app(comp left). app(" "). app(comp repr()). app(" ")

        leftType  := comp left  getType()
        while(leftType  instanceOf?(ReferenceType)) { leftType  = leftType  as ReferenceType inner }

        rightType := comp right getType()
        while(rightType instanceOf?(ReferenceType)) { rightType = rightType as ReferenceType inner }

        if(!rightType equals?(leftType)) {
            current app('('). app (leftType). app(") ")
        }
        current app(comp right)
    }

    visitTernary: func (tern: Ternary) {
        current app(tern condition). app(" ? "). app(tern ifTrue). app(" : "). app(tern ifFalse)
    }

    visitVarArg: func (varArg: VarArg) {
        if(varArg name) {
            visitVariableDecl(varArg) // ooc-style varargs
        } else {
            current app("...") // C-style varargs
        }
    }

    visitAddressOf: func (node: AddressOf) {
        if(node expr instanceOf?(VariableAccess)) {
            varAcc := node expr as VariableAccess
            if(varAcc getType() isGeneric()) {
                // generic variables are already pointers =)
                current app(varAcc); return
            }
            if(varAcc getType() instanceOf?(ReferenceType)) {
                visitVariableAccess(varAcc, false); return
            }
        }

        if(node expr instanceOf?(Dereference)) {
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
        body := node getBody()
        numNodes := body size
        isFirst := true

        for((j, statement) in body) {
            if (j < numNodes - 1 && statement instanceOf?(VariableAccess)) {
                // that's a no-op, skip it
                continue
            }

            if (isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            current app(statement)
        }
        current app(")")
    }

    visitVersionBlock: func (node: VersionBlock) {
        VersionWriter writeStart(this, node getSpec())
        for(statement in node getBody()) {
            writeLine(statement)
        }
        VersionWriter writeEnd(this, node getSpec())
    }

}
