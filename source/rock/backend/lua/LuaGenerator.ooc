import io/[File, FileWriter, BufferWriter]
import structs/[Bag, HashBag, MultiMap, List, ArrayList]
import text/json/Generator

import ../../frontend/[BuildParams, Token]

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference, FuncType, BaseType, PropertyDecl,
    EnumDecl, OperatorDecl, InterfaceDecl, InterfaceImpl, Version, TypeList]

import ../../backend/cnaughty/[FunctionDeclWriter, Skeleton, AwesomeWriter, CGenerator,
        ClassDeclWriter, CoverDeclWriter, EnumDeclWriter]

LuaGenerator: class extends CGenerator {

    outFile: File
    funcs, bind, types, imports: Buffer
    funcsWriter, bindWriter, typesWriter, importsWriter: AwesomeWriter

    init: func (=params, =module) {
        outFile = File new(params outPath getPath(), module getPath(".lua"))
        outFile parent mkdirs()

        types = Buffer new()
        typesWriter = AwesomeWriter new(this, BufferWriter new(types))
        typesWriter app("local _typesdeclared = false"). nl().
                    app("function _module.declare_types()"). tab(). nl().
                    app("if _typesdeclared then return end"). nl().
                    app("_typesdeclared = true"). nl().
                    app("howling.import_types(_imports)"). nl(). nl().
                    app("ffi.cdef[["). nl()

        funcs = Buffer new()
        funcsWriter = AwesomeWriter new(this, BufferWriter new(funcs))
        funcsWriter app("local _funcsdeclared = false"). nl().
                    app("function _module.declare_and_bind_funcs()"). tab(). nl().
                    app("if _funcsdeclared then return end"). nl().
                    app("_funcsdeclared = true"). nl().
                    app("howling.import_funcs(_imports)"). nl(). nl().
                    app("ffi.cdef[["). nl()

        bind = Buffer new()
        bindWriter = AwesomeWriter new(this, BufferWriter new(bind))
        bindWriter tab(). nl()

        imports = Buffer new()
        importsWriter = AwesomeWriter new(this, BufferWriter new(imports))

        current = funcsWriter
    }

    write: func {
        visitModule(module)
    }

    /** generate now, actually. */
    close: func {
        writer := FileWriter new(outFile)
        // close the types declaration
        typesWriter app("]]"). untab(). nl().
                    app("end"). nl(). nl()
        // add the binds to the funcs
        funcsWriter app("]]"). nl().
                    app(bind toString()). untab(). nl().
                    app("end"). nl(). nl()

        // write the funcs part
        writer write("local howling = require(\"howling\")\n").
               write("local _module = howling.Module:new(\"#{module getFullName()}\")\n").
               write("local ffi = require(\"ffi\")\n\n").
               write(imports toString()).
               write(types toString()).
               write(funcs toString())
        // and finally, return the new module.
        writer write("return _module\n")
        writer close()
    }

    shouldBindFunction: func (node: FunctionDecl) -> Bool {
        // Skip versioned functions
        if(node getVersion())
            return false
        // We could probably load extern functions, but let's not do that. (TODO?)
        if(node isExtern())
            return false
        // Skip main
        if(node isEntryPoint())
            return false
        return true
    }

    /** Write the function prototype to the funcs buffer. */
    visitFunctionDecl: func (node: FunctionDecl) {
        if(!shouldBindFunction(node)) return
        current = funcsWriter
        // funcs: write the function prototype
        FunctionDeclWriter writeFuncPrototype(this, node)
        current app(';') .nl()
        // bind: bind a function if it isn't a member.
        // if it is a member, `visitClassDecl` does the binding.
        if(!node isMember()) {
            current = bindWriter
            bindWriter app("_module:func(\"")
            FunctionDeclWriter writeSuffixedName(this, node)
            bindWriter app("\")") .nl()
        }
    }

    visitClassDecl: func (node: ClassDecl) {
        // Skip versioned classes
        if(node getVersion())
            return
        if(node isMeta)
            return
        // write the struct typedefs to `types` (makes them opaque, but that
        // should be enough for now)
        current = typesWriter
        ClassDeclWriter writeStructTypedef(this, node)
        typesWriter nl()
        generateClasslike(node)
    }

    /** Classes and covers. */
    generateClasslike: func (node: TypeDecl) {
        // Collect all functions to bind them.
        functions := ArrayList<String> new()
        for(function in node meta functions) {
            // Ignore __...__ functions (TODO?)
            if(function name startsWith?("__") &&
                function name endsWith?("__"))
                continue
            if(!shouldBindFunction(function)) continue
            // Write the funcs code
            function accept(this)
            name := function name
            if(function getSuffix())
                name = "%s_%s" format(name, function getSuffix())
            functions add(name)
        }
        // Skip closures
        if(node name startsWith?("_") && node name endsWith?("_ctx"))
            return
        // Write the bind code.
        bindWriter app("local _class = _module:class(\"#{node name}\", {"). tab(). nl().
                   app("functions = {"). tab(). nl()
        first := true
        for(name in functions) {
            if(!first) bindWriter app(','). nl()
            else first = false
            bindWriter app('"'). app(name). app('"')
        }
        bindWriter untab(). nl(). app("}"). untab(). nl(). app("})"). nl()
    }

    visitCoverDecl: func (node: CoverDecl) {
        // Skip versioned classes
        if(node getVersion())
            return
        // Write the typedef to `types`
        current = typesWriter
        // if we are binding an extern type, // we need an opaque type definition as well.
        // but let's assume that SDK definitions don't need that. (TODO)
        if(node fromType) {
            fromName := node fromType getName()
            // we don't need an opaque type if we're covering structs or unions
            if(!(fromName startsWith?("struct ") || fromName startsWith?("union") ||
                module getUseDef() identifier == "sdk")) {
                typesWriter app("typedef struct ___#{fromName} #{fromName};"). nl()
            }
        }
        CoverDeclWriter writeTypedef(this, node)
        typesWriter nl()
        // Some types can't be bound. (That is, primitive types!)
        /*from_ := node getFromType()
        if(from_ && !from_ instanceOf?(SugarType))
            return
        // Also, extern covers.
        if(node isExtern())
            return
        generateClasslike(node)*/
    }


    visitVariableDecl: func (node: VariableDecl) {
        super(node)
    }

    visitEnumDecl: func (node: EnumDecl) {
        // Enums are "wrapped" by typedef'ing them to int, for now. TODO.
        if(!node isExtern()) {
            typesWriter app("typedef int "). app(node underName()). app(';'). nl()
        }
    }

    visitOperatorDecl: func (node: OperatorDecl) {

    }

    visitInterfaceDecl: func (node: InterfaceDecl) {

    }

    visitInterfaceImpl: func (node: InterfaceImpl) {

    }

    visitModule:             func (node: Module) {
        // Import the imports!
        importsWriter app("local _imports = {"). tab()
        first := true
        for(imp in module getGlobalImports()) {
            if(!first) importsWriter app(',')
            first = false
            imported := imp getModule()
            path := "#{imported getUseDef() identifier}:#{imported path}"
            importsWriter nl(). app("\"#{path}\"")
        }
        importsWriter untab(). nl(). app("}"). nl(). nl()
        for(function in node functions)
            function accept(this)
        for(type in node types)
            type accept(this)
        for(op in node operators) {
            visitOperatorDecl(op)
        }
        // TODO: Don't write global variables (yet)
/*        for(child in node body)
            if(child instanceOf?(VariableDecl))
                child accept(this)*/
    }
}
