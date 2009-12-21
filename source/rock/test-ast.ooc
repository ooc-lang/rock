import io/FileWriter
import frontend/Token
import middle/[BinaryOp, IntLiteral, StringLiteral, RangeLiteral,
    Module, FunctionDecl, VariableDecl, VariableAccess, Type,
    FunctionCall, Foreach, Include, Import, Use, ClassDecl, CoverDecl,
    TypeDecl]
import backend/CGenerator

outPath := "rock_tmp"

main: func {
    
    addtest()
    classtest()
    
}

classtest: func {
    
    module := Module new("class-test", nullToken)
    
    fMain := FunctionDecl new("main", nullToken)
    module addFunction(fMain)
    
    dog := ClassDecl new("Dog", BaseType new("Object", nullToken), nullToken)
    module addType(dog)
    
    shout := FunctionDecl new("shout", nullToken)
    dog addFunction(shout)
    
    call := FunctionCall new("printf", nullToken)
    call args add(StringLiteral new("Woof, woof!", nullToken))
    shout body add(call)
    
    CGenerator new(outPath, module) write() .close()
    
}

addtest: func {
    
    module := Module new("add-test", nullToken)
    
    module includes add(Include new("stdio", IncludeModes PATHY))
    
    fMain := FunctionDecl new("main", nullToken)
    module addFunction(fMain)
    
    answer := VariableDecl new(BaseType new("int", nullToken), nullToken)
    answer atoms add(Atom new("answer", IntLiteral new(39, nullToken)))
    fMain body add(answer)
    
    add := BinaryOp new(
        VariableAccess new("answer", nullToken),
        IntLiteral new(3, nullToken),
        OpTypes addAss,
        nullToken
    )
    fMain body add(add)
    
    call := FunctionCall new("printf", nullToken)
    call args add(StringLiteral new("answer = %d\\n", nullToken))
    call args add(VariableAccess new("answer", nullToken))
    fMain body add(call)
    
    iDecl := VariableDecl new(BaseType new("int", nullToken), Atom new("i"), nullToken)
    fMain body add(iDecl)
    
    foreach := Foreach new(
        VariableAccess new("i", nullToken),
        RangeLiteral new(
            IntLiteral new(0, nullToken),
            IntLiteral new(10, nullToken),
            nullToken
        ),
        nullToken
    )
    call2 := FunctionCall new("printf", nullToken)
    call2 args add(StringLiteral new("%d\\n", nullToken))
    call2 args add(VariableAccess new("i", nullToken))
    foreach body add(call2))
    fMain body add(foreach)
    
    CGenerator new(outPath, module) write() .close()
    
}
