import io/[File, FileWriter]
import structs/[Bag, HashBag]
import text/json/Generator

import ../../frontend/BuildParams

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference, FuncType, BaseType]
    
JSONGenerator: class extends Visitor {
    
    params: BuildParams
    outFile: File
    module: Module
    objects, root: HashBag

    init: func (=params, =module) {
        outFile = File new(params outPath getPath() + File separator + module getSourceFolderName(), module getPath(".json"))
        outFile parent() mkdirs()
        root = HashBag new()
        objects = HashBag new()
        /* build the structure! */
        root put("entities", objects)
        root put("name", module getPath())

        globalImports := Bag new()
        for(imp in module getGlobalImports())
            globalImports add(imp getModule() getPath())
        root put("globalImports", globalImports)

        namespacedImports := HashBag new()
        for(ns in module namespaces) {
            modules := Bag new()
            for(imp in ns getImports()) {
                modules add(imp getModule() getPath())
            }
            namespacedImports put(ns getName(), modules)
        }
        root put("namespacedImports", namespacedImports)

        uses := Bag new()
        for(uze in module getUses()) {
            uses add(uze identifier)
        }
        root put("uses", uses)
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
        generate(writer, root)
        writer close()
    }

    visitClassDecl: func (node: ClassDecl) {
        if(node isMeta)
            return
        obj := HashBag new()
        /* `name` */
        obj put("name", node name as String)
        /* `type` */
        obj put("type", "class")
        /* `fullName` */
        obj put("fullName", node underName())
        /* `tag` */
        obj put("tag", node name as String)
        /* `extends` */
        if(node getSuperRef() != null) {
            obj put("extends", node getSuperRef() name as String)
        } else {
            obj put("extends", null)
        }
        /* TODO: genericTypes */
        /* `members` */
        members := Bag new()
        /* methods */
        for(function in node meta functions) {
            member := Bag new()
            member add(function name) .add(buildFunctionDecl(function, "method"))
            members add(member)
        }
        /* variables */
        for(variable in node variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        /* static variables */
        for(variable in node meta variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        obj put("members", members)
        objects put(node name, obj)
    }

    visitCoverDecl: func (node: CoverDecl) {
        obj := HashBag new()
        /* `name` */
        obj put("name", node name as String)
        /* `type` */
        obj put("type", "cover")
        /* `tag` */
        obj put("tag", node name as String)
        /* `fullName` */
        obj put("fullName", node underName())
        /* `extends` */
        if(node getSuperRef() != null) {
            obj put("extends", node getSuperRef() name as String)
        } else {
            obj put("extends", null)
        }
        /* `from` */
        if(node fromType != null) {
            obj put("from", node fromType toString())
        } else {
            obj put("from", null)
        }
        /* `members` */
        members := Bag new()
        for(function in node functions) {
            member := Bag new()
            member add(function name) .add(buildFunctionDecl(function, "method"))
            members add(member)
        }
        for(variable: VariableDecl in node variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        obj put("members", members)
        objects put(node name, obj)
    }

    visitFunctionDecl: func (node: FunctionDecl) {
        /* add to the objects. */
        obj := buildFunctionDecl(node, "function")
        objects put(node name, obj)
    }

    buildFunctionDecl: func ~typed (node: FunctionDecl, type: String) -> HashBag {
        obj := HashBag new()
        /* `name` */
        obj put("name", node name)
        /* `tag` */
        if(type == "method") {
            obj put("tag", "method(%s, %s)" format(node owner name, node name))
        } else {
            obj put("tag", node name)
        }
        /* `type` */
        obj put("type", type)
        /* `extern` */
        if(node isExtern()) {
            if(!node isExternWithName())
                obj put("extern", true)
            else
                obj put("extern", node externName)
        } else {
            obj put("extern", false)
        }
        /* `unmangled` */
        if(node isUnmangled()) {
            if(!node isUnmangledWithName())
                obj put("unmangled", true)
            else
                obj put("unmangled", node getUnmangledName())
        }
        else {
            obj put("unmangled", false)
        }
        /* `fullName` */
        obj put("fullName", node getFullName())
        /* `modifiers` */
        modifiers := Bag new()
        if(node isAbstract())
            modifiers add("abstract")
        if(node isStatic())
            modifiers add("static")
        if(node isInline())
            modifiers add("inline")
        if(node isFinal())
            modifiers add("final")
        obj put("modifiers", modifiers)
        /* generic types */
        genericTypes := Bag new()
        for(typeArg in node typeArgs) {
            genericTypes add(typeArg name as String)
        }
        obj put("genericTypes", genericTypes)
        /* return type */
        if(node hasReturn()) {
            obj put("returnType", resolveType(node getReturnType()))
        } else {
            obj put("returnType", null)
        }
        /* arguments */
        args := Bag new()
        for(arg in node args) {
            l := Bag new()
            l add(arg name as String) /* TODO: why is that needed? */
            if(arg instanceOf(VarArg))
                l add("")
            else
                l add(resolveType(arg type)) /* this handles generic types well. */
            if(arg isConst) {
                m := Bag new()
                m add("const")
                l add(m)
            } else {
                l add(null)
            }
            args add(l)
        }
        obj put("arguments", args)
        obj
    }

    visitVariableDecl: func (node: VariableDecl) {
        /* add to the objects */
        obj := buildVariableDecl(node, "globalVariable")
        objects put(node name, obj)
    }

    buildVariableDecl: func (node: VariableDecl, type: String) -> HashBag {
        obj := HashBag new()
        /* `name` */
        obj put("name", node name)
        /* `extern` */
        if(node isExtern()) {
            if(node externName isEmpty())
                obj put("extern", true)
            else
                obj put("extern", node externName)
        } else {
            obj put("extern", false)
        }
        /* `fullName` */
        obj put("fullName", node getFullName())
         /* `unmangled` */
        if(node isUnmangled()) {
            if(!node isUnmangledWithName())
                obj put("unmangled", true)
            else
                obj put("unmangled", node getUnmangledName())
        }
        else {
            obj put("unmangled", false)
        }
        /* `type` */
        obj put("type", type)
        /* `tag` */
        if(type == "field") {
            obj put("tag", "field(%s, %s)" format(node owner name, node name))
        } else {
            obj put("tag", node name)
        }
        /* `modifiers` */
        modifiers := Bag new()
        if(node isStatic)
            modifiers add("static")
        if(node isConst)
            modifiers add("const")
        obj put("modifiers", modifiers)
        /* `value` */
        if(node expr != null) {
            obj put("value", node expr toString())
        } else {
            obj put("value", null)
        }
        /* `varType` */
        obj put("varType", resolveType(node type))
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
