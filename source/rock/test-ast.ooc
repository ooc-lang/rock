import io/FileWriter
import frontend/Token
import middle/[BinaryOp, IntLiteral, StringLiteral, Module, FunctionDecl,
    Line, VariableDecl, VariableAccess, Type, FunctionCall]
import backend/CGenerator

main: func {
    
    module := Module new("add-test", nullToken)
    
    main := FunctionDecl new("main", nullToken)
    module addFunction(main)
    
    answer := VariableDecl new(Type new("int"), nullToken)
    answer atoms add(Atom new("answer", IntLiteral new(39, nullToken)))
    main body add(Line new(answer))
    
    add := BinaryOp new(
        VariableAccess new("answer", nullToken),
        IntLiteral new(3, nullToken),
        OpType addAss,
        nullToken
    )
    main body add(Line new(add))
    
    call := FunctionCall new("printf", nullToken)
    call args add(StringLiteral new("answer = %d\\n", nullToken))
    call args add(VariableAccess new("answer", nullToken))
    main body add(Line new(call))
    
    CGenerator new("rock_tmp", module) write() .close()
    
}
