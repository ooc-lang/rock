import ../middle/[ControlStatement, Conditional, If, Else, While,
    Foreach, Line, RangeLiteral]
import Skeleton

ControlStatementWriter: abstract class extends Skeleton {
    
    /** Write a conditional */
    writeConditional: static func (this: This, name: String, cond: Conditional) {
        current app(name). app(" (" ). app(cond condition). app(") {"). tab(). nl()
        for(line: Line in cond body) {
            line accept(this)
        }
        current untab(). nl(). app("}")
    }
    
    write: static func ~_if (this: This, if1: If) {
        writeConditional(this, "if", if1)
    }
    
    write: static func ~_else (this: This, else1: Else) {
        writeConditional(this, "else", else1)
    }
    
    write: static func ~_while (this: This, while1: While) {
        writeConditional(this, "while", while1)
    }
    
    write: static func ~_foreach (this: This, foreach: Foreach) {
        if(!foreach collection class instanceof(RangeLiteral)) {
            Exception new(this, "Iterating over not a range but a " + foreach collection class name) throw()
        }
        range := foreach collection as RangeLiteral
        current app("for (").
            app(foreach variable). app(" = "). app(range lower). app("; ").
            app(foreach variable). app(" < "). app(range upper). app("; ").
            app(foreach variable). app("++) {").
        tab()
        for(line: Line in foreach body) {
            line accept(this)
        }
        current untab(). nl(). app("}")
    }
    
}

