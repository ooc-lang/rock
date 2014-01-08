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
        ClassDeclWriter, CoverDeclWriter]

LuaGenerator: class extends CGenerator {

    outFile: File
    cdecl, bind, types, imports: Buffer
    cdeclWriter, bindWriter, typesWriter, importsWriter: AwesomeWriter

    init: func (=params, =module) {
        outFile = File new(params outPath getPath(), module getPath(".lua"))
        outFile parent mkdirs()

        cdecl = Buffer new()
        cdeclWriter = AwesomeWriter new(this, BufferWriter new(cdecl))
        cdeclWriter tab(). nl()

        types = Buffer new()
        typesWriter = AwesomeWriter new(this, BufferWriter new(types))

        bind = Buffer new()
        bindWriter = AwesomeWriter new(this, BufferWriter new(bind))
        bindWriter tab(). nl()

        imports = Buffer new()
        importsWriter = AwesomeWriter new(this, BufferWriter new(imports))

        current = cdeclWriter
    }

    write: func {
        visitModule(module)
    }

    /** generate now, actually. */
    close: func {
        writer := FileWriter new(outFile)
        // write the cdecl part
            // bind code: Add module
        writer write("local howling = require(\"howling\")\n").
               // howling has to know about our module as soon as possible
               // to prevent issues with double inclusion.
               write("local _module = howling.Module:new(\"#{module getFullName()}\")\n").
               write("local ffi = require(\"ffi\")\n\n").
               write("ffi.cdef[[\n")
        writer write(types toString()).
               write("]]\n\n").
               write(imports toString()).
               write("\n").
               write("_initialized = false\n").
               write("function _module.init ()\n").
               write("    if _initialized then return end\n").
               write("    _initialized = true\n").
               write("    for k,v in pairs(_imports) do\n").
               write("        howling.loader:load(k).init()\n").
               write("    end\n").  
               write("    ffi.cdef[[\n").
               write(cdecl toString())
        writer write("    ]]\n\n")
        // write the bind part
        writer write(bind toString()).
               write("\nend\n")
        // and finally, return the new module.
        writer write("\nreturn _module\n")
        writer close()
    }

    /** Write the function prototype to the cdecl buffer. */
    visitFunctionDecl: func (node: FunctionDecl) {
        // Skip versioned functions
        if(node getVersion())
            return
        current = cdeclWriter
        // cdecl: write the function prototype
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
                continue;
            // Write the cdecl code
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
        CoverDeclWriter writeTypedef(this, node)
        typesWriter nl()
        generateClasslike(node)
    }


    visitVariableDecl: func (node: VariableDecl) {
        super(node)
    }

    visitEnumDecl: func (node: EnumDecl) {

    }

    visitOperatorDecl: func (node: OperatorDecl) {

    }

    visitInterfaceDecl: func (node: InterfaceDecl) {

    }

    visitInterfaceImpl: func (node: InterfaceImpl) {

    }

    visitModule:             func (node: Module) {
        // Import the imports!
        importsWriter app("local _imports = {}"). nl()
        for(imp in module getGlobalImports()) {
            imported := imp getModule()
            path := "#{imported getUseDef() identifier}:#{imported path}"
            importsWriter app("_imports[\"#{path}\"] = howling.loader:load(\"#{path}\", true)"). nl()
        }
        importsWriter nl()
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
