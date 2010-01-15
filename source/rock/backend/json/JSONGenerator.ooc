use yajl

import io/[File, FileWriter]
import yajl/Yajl

import ../../frontend/BuildParams

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference]
    
JSONGenerator: class extends Visitor {
    
    params: BuildParams
    outFile: File
    module: Module
    root: ValueMap

    init: func (=params, =module) {
        outFile = File new(params getOutputPath(module, ".json"))
        outFile parent() mkdirs()
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

    visitClassDecl: func (node: ClassDecl) {
        if(node isMeta)
            return
        obj := ValueMap new()
        /* `name` */
        obj putValue("name", node name as String)
        /* `type` */
        obj putValue("type", "class")
        /* `tag` */
        obj putValue("tag", node name as String)
        /* `extends` */
        if(node superRef() != null) {
            obj putValue("extends", node superRef() name as String)
        } else {
            obj putValue("extends", null)
        }
        /* TODO: genericTypes */
        /* `members` */
        members := ValueList new()
        for(function in node meta functions) {
            member := ValueList new()
            member addValue(function name) .addValue(buildFunctionDecl(function, "memberFunction"))
            members addValue(member)
        }
        for(variable in node variables) {
            member := ValueList new()
            member addValue(variable name) .addValue(buildVariableDecl(variable, "field"))
            members addValue(member)
        }
        obj putValue("members", members)
        root putValue(node name, obj)
    }

    visitCoverDecl: func (node: CoverDecl) {
        obj := ValueMap new()
        /* `name` */
        obj putValue("name", node name as String)
        /* `type` */
        obj putValue("type", "cover")
        /* `tag` */
        obj putValue("tag", node name as String)
        /* `extends` */
        if(node superRef() != null) {
            obj putValue("extends", node superRef() name as String)
        } else {
            obj putValue("extends", null)
        }
        /* `from` */
        if(node fromType != null) {
            obj putValue("from", node fromType toString())
        } else {
            obj putValue("from", null)
        }
        /* `members` */
        members := ValueList new()
        for(function in node functions) {
            member := ValueList new()
            member addValue(function name) .addValue(buildFunctionDecl(function, "memberFunction"))
            members addValue(member)
        }
        for(variable: VariableDecl in node variables) {
            member := ValueList new()
            member addValue(variable name) .addValue(buildVariableDecl(variable, "field"))
            members addValue(member)
        }
        obj putValue("members", members)
        root putValue(node name, obj)
    }

    visitFunctionDecl: func (node: FunctionDecl) {
        /* add to the root */
        obj := buildFunctionDecl(node, "function")
        root putValue(node name, obj)
    }

    buildFunctionDecl: func ~typed (node: FunctionDecl, type: String) -> ValueMap {
        obj := ValueMap new()
        /* `name` */
        obj putValue("name", node name)
        /* `tag` */
        if(type == "memberFunction") {
            obj putValue("tag", "memberFunction(%s, %s)" format(node owner name, node name))
        } else {
            obj putValue("tag", node name)
        }
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

    visitVariableDecl: func (node: VariableDecl) {
        /* add to the root */
        obj := buildVariableDecl(node, "globalVariable")
        root putValue(node name, obj)
    }

    buildVariableDecl: func (node: VariableDecl, type: String) -> ValueMap {
        obj := ValueMap new()
        /* `name` */
        obj putValue("name", node name)
        /* `extern` */
        if(node isExtern()) {
            if(node externName isEmpty())
                obj putValue("extern", true)
            else
                obj putValue("extern", node externName)
        } else {
            obj putValue("extern", false)
        }
        /* `type` */
        obj putValue("type", type)
        /* `tag` */
        if(type == "field") {
            obj putValue("tag", "field(%s, %s)" format(node owner name, node name))
        } else {
            obj putValue("tag", node name)
        }
        /* `modifiers` */
        modifiers := ValueList new()
        if(node isStatic)
            modifiers addValue("static")
        if(node isConst)
            modifiers addValue("const")
        obj putValue("modifiers", modifiers)
        /* `value` */
        if(node expr != null) {
            obj putValue("value", node expr toString())
        } else {
            obj putValue("value", null)
        }
        /* `varType` */
        obj putValue("varType", resolveType(node type))
        obj
    }
    
    visitType:               func (node: Type) {}
    
    visitModule:             func (node: Module) {
        for(function in node functions)
            function accept(this)
        for(type in node types)
            type accept(this)
        /* TODO: catch global variables */
    }


}
