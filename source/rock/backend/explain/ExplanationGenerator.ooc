import io/[File, FileWriter]
import structs/[Bag, HashBag]
import text/json/Generator
import text/Buffer

import ../../frontend/BuildParams

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
Argument, Statement, AddressOf, Dereference, FuncType, BaseType, PropertyDecl,
EnumDecl, OperatorDecl, InterfaceDecl, InterfaceImpl, Version]

ExplanationGenerator: class extends Visitor {
  params: BuildParams
  outFile: File
  module: Module
  explanation: Buffer

  init: func (=params, =module) {
    outFile = File new(params outPath getPath() + File separator + module getSourceFolderName(), module getPath(".markdown"))
    outFile parent() mkdirs()
    explanation = Buffer new()
    /* build the structure! */
    addObject("# "+module getPath())
    addObject()

    addObject("This file depends on *"+(module getGlobalImports() size() toString())+"* other files during runtime.")
    addObject("Some of these are **import**s, or files that were manually added for dependency through an **import** statement.")
    addObject("This file depends on the following files:")
    addObject()

    i := 1
    for(imp in module getGlobalImports()) {
      addObject((i toString())+". "+imp getModule() getPath())
      i += 1
    }
    for(ns in module namespaces) {
      for(imp in ns getImports()) {
        addObject((i toString())+". "+imp getModule() getPath())
        i += 1
      }
    }
    addObject()

    if (module getUses() size() > 0) {
      addObject("This file also **use**s *"+(module getUses() size() toString())+"* other file(s). *use* files are located in $OOC_LIBS.")
      addObject("They contain extra information about a particular ooc library, such as name, description, what C libraries are included, etc...")
      addObject("This file **use**s the following libraries:")
      addObject()
      i := 1
      for(uze in module getUses()) {
        addObject((i toString())+". "+uze identifier)
      }
      addObject()      
    }
  }

  write: func {
    visitModule(module)
  }

  addObject: func ~newline {
    explanation append("\n")
  }
  
  addObject: func ~withoption (text: String, option: String) {
    if (option == "field") explanation append("    "+text+"\n")
    else explanation append(text+"\n")
  }

  addObject: func (text: String) {
    explanation append(text+"\n")
  }

  close: func {
    writer := FileWriter new(outFile)
    writer write(explanation toString())
    writer close()
  }
  
  resolveType: func (type: Type) -> String {
    if(type instanceOf?(FuncType)) {
      return "Func"
    } else if(type instanceOf?(PointerType)) {
      return "pointer(%s)" format(resolveType(type as PointerType inner))
    } else if(type instanceOf?(ReferenceType)) {
      return "reference(%s)" format(resolveType(type as ReferenceType inner))
    } else {
      return type as BaseType name
    }
  }
  
  translateVersionSpec: func (spec: VersionSpec) -> String {
    match (spec class) {
      case VersionName => {
        return spec as VersionName name
      }
      case VersionNegation => {
        return "not(%s)" format(translateVersionSpec(spec as VersionNegation spec))
      }
      case VersionAnd => {
        mySpec := spec as VersionAnd
        return "and(%s,%s)" format(
          translateVersionSpec(mySpec specLeft),
        translateVersionSpec(mySpec specRight))
      }
      case VersionOr => {
        mySpec := spec as VersionOr
        return "or(%s,%s)" format(
          translateVersionSpec(mySpec specLeft),
        translateVersionSpec(mySpec specRight))
      }
      case => {
        Exception new("Unknown version spec class: %s" format(spec class name)) throw()
      }
    }
    null
  }
  
  visitModule: func (node: Module) {
    for(function in node functions) function accept(this)
    for(type in node types) type accept(this)
    /*for(op in node operators) visitOperatorDecl(op)*/
    for(child in node body) if(child instanceOf?(VariableDecl)) child accept(this)   
  }
  
  visitType: func (node: Type) {}
  
  visitClassDecl: func (node: ClassDecl) {
    if(node isMeta) return
    addObject("## "+(node name as String)+" class")
    addObject()
    
    addObject("class attributes:")
    addObject()
    
    if (node getSuperRef() != null) addObject("* "+(node name as String)+" **extend**s the "+(node getSuperRef() name as String)+" class: "+(node name as String)+" inherits the properties and methods of "+(node getSuperRef() name as String)+". *ooc* does **not** support multiple inheritance, meaning one cannot **extend** multiple classes"); addObject()
    if (node isAbstract) addObject("* "+(node name as String)+" is **abstract**; it cannot be instantiated, though it still can be extended by other classes"); addObject()
    if (node isFinal) addObject("* "+(node name as String)+" is **final**; it cannot be further extended or subclassed"); addObject()
    //if (node doc != "") { addObject("* "+(node name as String)+" has attached documentation (/\*\* \*/):"); addObject("    "+node doc); addObject() }
    if (node typeArgs size() > 0) {
      addObject("* "+(node name as String)+" is a generic class with *"+(node typeArgs size() toString())+"* generic type(s). Generic types are placeholders for more specific types a class could operate on. "+(node name as String)+" features the following generic types:"); addObject()
      for(typeArg in node typeArgs) addObject("    * "+typeArg name as String)
      addObject()
    }
    
    addObject("class members:")
    addObject()
    
    addObject("* Variables:")
    addObject()
    for(variable in node variables) {
      buildVariableDecl(variable, "field")
      addObject()
    }
    addObject("* Methods:")
    addObject()
    for(function in node meta functions) {
      buildFunctionDecl(function, "field")
      addObject()
    }
    /* static variables 
    for(variable in node meta variables) {
      member := Bag new()
      member add(variable name) .add(buildVariableDecl(variable, "field"))
      members add(member)
    }
    obj put("members", members)
    addObject(node name, obj)
    for(idecl in node getInterfaceDecls())
    visitInterfaceImpl(idecl)*/
  }
  
  visitFunctionDecl: func (node: FunctionDecl) {
    addObject("## "+node name+" function")
    buildFunctionDecl(node, "function")
    addObject()
  }
  
  buildFunctionDecl: func ~typed (node: FunctionDecl, type: String) {
      name := null as String
      if(node suffix)
          name = "%s~%s" format(node name, node suffix)
      else
          name = node name
          
      addObject("* *"+name+"*:",type)
      
      if (node isExtern()) addObject("    * "+name+" is an **extern** function. "+node externName+" is defined elsewhere in other source files, maybe even in a C header file",type)
      if (node isAbstract()) addObject("    * "+name+" is **abstract**. Abstract functions are defined in abstract classes", type)
      if (node isStatic()) addObject("    * "+name+" is **static**; it has a class scope and is called by the class, not by an instance of the class", type)
      if (node isInline()) addObject("    * "+name+" is **inline**; calls to this function will be substituted with the actual function code. Functions that are called often would be optimal **inline** functions", type)
      if (node args size() > 0) {
        addObject("    * "+name+" takes *"+node args size() toString()+"* argument(s):",type)
        for(arg in node args) if(!arg instanceOf?(VarArg)) addObject("        * "+(arg name as String)+" of type *"+(resolveType(arg type))+"*", type)
      }
      if (node returnType != voidType) addObject("    * "+name+" has a non-void return type: *"+node getReturnType() getName()+"*", type)
      if (node typeArgs size() > 0) {
        addObject("    * "+name+" is a generic function with *"+(node typeArgs size() toString())+"* generic types:", type)
        for(typeArg in node typeArgs) addObject("        * "+typeArg name as String, type)
      }  
      //if (node doc != "") { addObject("    * "+name+" has attached documentation (/\*\* \*/):", type); addObject("       "+node doc,type) }
      
      /* `unmangled`
      if(node isUnmangled()) {
          if(!node isUnmangledWithName())
              obj put("unmangled", true)
          else
              obj put("unmangled", node getUnmangledName())
      }
      else {
          obj put("unmangled", false)
      }*/
  }
  
  visitCoverDecl: func (node: CoverDecl) {
    addObject("## "+node name as String+" cover:")
    addObject()
    
    addObject("cover attributes:")
    addObject()
    
    if (node getSuperRef() != null) addObject("* "+node name as String+" **extend**s "+node getSuperRef() name as String); addObject()
    if (node fromType != null) addObject("* "+node name as String+" covers from "+node fromType toString()+". Covers could cover other covers or even other classes"); addObject()
    
    addObject("cover members:")
    addObject()
    
    addObject("* Variables:")
    addObject()
    for(variable: VariableDecl in node variables) {
      buildVariableDecl(variable, "field")
      addObject()
    }  
    addObject("* Methods:")
    addObject()
    for(function in node functions) {
      buildFunctionDecl(function, "field")
      addObject()
    }   
  }
  
  visitVariableDecl: func (node: VariableDecl) {
    addObject("## "+node name+" variable")
    buildVariableDecl(node, "globalVariable")
    addObject()
  }

  buildVariableDecl: func (node: VariableDecl, type: String) -> HashBag {
      addObject("* *"+node name+"*:",type)
      
      addObject("    * "+node name+" is of type: *"+resolveType(node type)+"*",type)
      if (node isStatic) addObject("    * "+node name+" is a **static** variable",type)
      if (node isConst) addObject("    * "+node name+" is a **const**. This implies that "+node name+" points to constant data",type)
      if (node expr != null) addObject("    * "+node name+" has the expression: *"+node expr toString()+"*",type)
  }
}