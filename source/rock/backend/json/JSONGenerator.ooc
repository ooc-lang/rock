use yajl

import io/[File, FileWriter]
import yajl/Yajl

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference]
    
JSONGenerator: class extends Visitor {
    outFile: File
    module: Module
    root: ValueMap

    init: func (=outFile, =module) {
        root = ValueMap new()
    }

    write: func {
        visitModule(module)
    }

    resolveType: func (type: Type) -> String {
        if(type instanceOf(FuncType)) {
            return "Func" /* TODO? */
        } else if(type instanceOf(PointerType)) {
            return "pointer(%s)" format(resolveType(type as PointerType inner))
        } else if(type instanceOf(ReferenceType)) {
            return "reference(%s)" format(resolveType(type as ReferenceType inner))
        } else {
            /* base type */
            return type as BaseType name /* TODO? */
        }
    }

    /** generate now, actually. */
    close: func {
        /* don't beautify, don't indent. */
        writer := FileWriter new(outFile)
        gen := Gen new(func (writer_: FileWriter, s: String, len: UInt) { writer_ write(s, len) }, writer)
        value := Value<ValueMap> new(ValueMap, root)
        value _generate(gen)
        writer close()
    }

    visitClassDecl:          func (node: ClassDecl) {
/*        obj := ValueMap new()
        /* `name` /
        obj putValue("name", node name)
        /* `type` /
        obj putValue("type", "class")
        /* `extends` /
        if(node superRef() != null) {
            obj putValue("extends", node superRef() name)
        } else {
            obj putValue("extends", null)
        }
        /* TODO: genericTypes /
        /* `members` /*/
        
    }
    visitCoverDecl:          func (node: CoverDecl) {}

    visitFunctionDecl: func (node: FunctionDecl) {
        /* add to the root */
        obj := buildFunctionDecl(node, "function")
        root putValue(node name, obj)
    }

    buildFunctionDecl: func ~typed (node: FunctionDecl, type: String) -> ValueMap {
        obj := ValueMap new()
        /* `name` */
        obj putValue("name", node name)
        /* `type` */
        obj putValue("type", type)
        /* `extern` */
        if(node isExtern()) {
            if(!node isExternWithName())
                obj putValue("extern", true)
            else
                obj putValue("extern", node externName)
        } else {
            obj putValue("extern", false)
        }
        /* `modifiers` */
        modifiers := ValueList new()
        if(node isAbstract)
            modifiers addValue("abstract")
        if(node isStatic)
            modifiers addValue("static")
        if(node isInline)
            modifiers addValue("inline")
        if(node isFinal)
            modifiers addValue("final")
        obj putValue("modifiers", modifiers)
        /* generic types */
        genericTypes := ValueList new()
        for(typeArg in node typeArgs) {
            genericTypes addValue(typeArg name as String)
        }
        obj putValue("genericTypes", genericTypes)
        /* return type */
        if(node hasReturn()) {
            obj putValue("returnType", resolveType(node getReturnType()))
        } else {
            obj putValue("returnType", null)
        }
        /* arguments */
        args := ValueList new()
        for(arg in node args) {
            l := ValueList new()
            l addValue(arg name as String) /* TODO: why is that needed? */
            l addValue(resolveType(arg type)) /* this handles generic types well. */
            if(arg isConst) {
                m := ValueList new()
                m addValue("const")
                l addValue(m)
            } else {
                l addValue(null)
            }
            args addValue(l)
        }
        obj putValue("arguments", args)
        obj
    }

    visitVariableDecl:       func (node: VariableDecl) {}
    
    visitType:               func (node: Type) {}
    
    visitModule:             func (node: Module) {
        for(function in node functions)
            function accept(this)
    }
    
    visitIf:                 func (node: If) {}
    visitElse:               func (node: Else) {}
    visitWhile:              func (node: While) {}
    visitForeach:            func (node: Foreach) {}
    
    visitRangeLiteral:       func (node: RangeLiteral) {}
    visitCharLiteral:        func (node: CharLiteral) {}
    visitStringLiteral:      func (node: StringLiteral) {}
    visitBoolLiteral:        func (node: BoolLiteral) {}
    visitIntLiteral:         func (node: IntLiteral) {}
    
    visitVariableAccess:     func (node: VariableAccess) {}
    visitFunctionCall:       func (node: FunctionCall) {}
    
    visitBinaryOp:           func (node: BinaryOp) {}
    visitParenthesis:        func (node: Parenthesis) {}
    
    visitReturn:             func (node: Return) {}

    visitCast:               func (node: Cast) {}
    visitComparison:         func (node: Comparison) {}
    
    visitTernary:            func (node: Ternary) {}
    
    visitVarArg:             func (node: VarArg) {}
    
    visitAddressOf:          func (node: AddressOf) {}
    visitDereference:        func (node: Dereference) {}


}
