import io/FileWriter
import frontend/Token
import middle/[Add, IntLiteral, Module, FunctionDecl, Line, VariableDecl, VariableAccess, Type]
import backend/CGenerator

main: func {
    
    module := Module new("add-test", nullToken)
    
    main := FunctionDecl new("main", nullToken)
    module addFunction(main)
    
    answer := VariableDecl new(Type new("int"), nullToken)
    answer atoms add(Atom new("answer", IntLiteral new(42, nullToken)))
    main body add(Line new(answer))
    
    add := Add new(
        VariableAccess new("answer", nullToken),
        IntLiteral new(3, nullToken),
        nullToken
    )
    main body add(Line new(add))
    
    CGenerator new("rock_tmp", module) write() .close()
    
}
