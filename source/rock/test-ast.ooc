import io/FileWriter
import frontend/Token
import middle/[BinaryOp, IntLiteral, StringLiteral, RangeLiteral,
    Module, FunctionDecl, Line, VariableDecl, VariableAccess, Type,
    FunctionCall, Foreach, Include, Import, Use]
import backend/CGenerator

main: func {
    
    module := Module new("add-test", nullToken)
    
    module includes add(Include new("stdio", IncludeModes PATHY))
    
    fMain := FunctionDecl new("main", nullToken)
    module addFunction(fMain)
    
    answer := VariableDecl new(Type new("int"), nullToken)
    answer atoms add(Atom new("answer", IntLiteral new(39, nullToken)))
    fMain body add(Line new(answer))
    
    add := BinaryOp new(
        VariableAccess new("answer", nullToken),
        IntLiteral new(3, nullToken),
        OpType addAss,
        nullToken
    )
    fMain body add(Line new(add))
    
    call := FunctionCall new("printf", nullToken)
    call args add(StringLiteral new("answer = %d\\n", nullToken))
    call args add(VariableAccess new("answer", nullToken))
    fMain body add(Line new(call))
    
    foreach := Foreach new(
        VariableDecl new(Type new("int"), Atom new("i"), nullToken),
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
    foreach body add(Line new(call2))
    fMain body add(Line new(foreach))
    
    CGenerator new("rock_tmp", module) write() .close()
    
}
