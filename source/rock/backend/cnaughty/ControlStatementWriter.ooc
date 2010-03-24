import ../../middle/[ControlStatement, Conditional, If, Else, While,
    Foreach, RangeLiteral, VariableDecl, VariableAccess, Match]
import Skeleton

ControlStatementWriter: abstract class extends Skeleton {
    
    /** Write a conditional */
    writeConditional: static func (this: This, name: String, cond: Conditional) {
        current app(name)
        if(cond condition != null) {
            current app(" (" ). app(cond condition). app(")")
        }
        current app(" {"). tab()
        for(stat in cond body) {
            writeLine(stat)
        }
        current untab(). nl(). app("}")
    }
    
    write: static func ~_if (this: This, if1: If) {
        writeConditional(this, "if", if1)
    }
    
    write: static func ~_else (this: This, else1: Else) {
        isIf := else1 getBody() size() == 1 && else1 getBody() first() instanceOf(If)
        
        if(isIf) {
            current app("else ")
            writeConditional(this, "if", else1 getBody() first() as If)
        } else {
            writeConditional(this, "else", else1)
        }
    }
    
    write: static func ~_while (this: This, while1: While) {
        writeConditional(this, "while", while1)
    }
    
    write: static func ~_foreach (this: This, foreach: Foreach) {
        if(!foreach collection instanceOf(RangeLiteral)) {
            Exception new(This, "Iterating over not a range but a " + foreach collection class name) throw()
        }
        access := foreach variable
        if(access instanceOf(VariableDecl)) {
            access = VariableAccess new(access as VariableDecl, access token)
        }
        
        range := foreach collection as RangeLiteral
        current app("for (").
            app(foreach variable). app(" = "). app(range lower). app("; ").
            app(access).           app(" < "). app(range upper). app("; ").
            app(access).           app("++) {").
        tab()
        for(stat in foreach body) {
            writeLine(stat)
        }
        current untab(). nl(). app("}")
    }
    
    write: static func ~_match (this: This, mat: Match) {
        isFirst := true
		for(caze in mat getCases()) {
			if(!isFirst) current app(" else ")

			if(caze getExpr() == null) {
				if(isFirst) current.app(" else ");
			} else {
                // FIXME: wtf? (from the j/ooc codebase)
				//if(case1 isFallthrough()) current app(' ')
				current app("if ("). app(caze getExpr()). app(")")
			}
			
			current app("{"). tab()
			
			for(stat in caze getBody()) {
				writeLine(stat)
			}
			
			current untab(). nl(). app("}")
			if(isFirst) isFirst = false;
		}
    }
    
}

