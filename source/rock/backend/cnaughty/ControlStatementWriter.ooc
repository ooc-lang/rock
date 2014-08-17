import rock/middle/[ControlStatement, Conditional, If, Else, While,
    Foreach, RangeLiteral, VariableDecl, VariableAccess, Match]
import Skeleton

ControlStatementWriter: abstract class extends Skeleton {

    /** Write a conditional */
    writeConditional: static func (this: Skeleton, name: String, cond: Conditional) {
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

    write: static func ~_if (this: Skeleton, if1: If) {
        writeConditional(this, "if", if1)
    }

    write: static func ~_else (this: Skeleton, else1: Else) {
        isIf := else1 getBody() getSize() == 1 && else1 getBody() first() instanceOf?(If)

        if(isIf) {
            current app("else ")
            writeConditional(this, "if", else1 getBody() first() as If)
        } else {
            writeConditional(this, "else", else1)
        }
    }

    write: static func ~_while (this: Skeleton, while1: While) {
        writeConditional(this, "while", while1)
    }

    write: static func ~_foreach (this: Skeleton, foreach: Foreach) {
        if(!foreach collection instanceOf?(RangeLiteral)) {
            Exception new(This, "Iterating over not a range but a " + foreach collection class name) throw()
        }
        access := foreach variable
        if(access instanceOf?(VariableDecl)) {
            access = VariableAccess new(access as VariableDecl, access token)
        }

        range := foreach collection as RangeLiteral
        current app("for ("). app(foreach variable). app(" = "). app(range lower)
        if(foreach indexVariable) current app(", "). app(foreach indexVariable). app(" = "). app(range lower)
        current app("; ").
            app(access).           app(" < "). app(range upper). app("; ").
            app(access).           app("++")
        if(foreach indexVariable) current app(", "). app(foreach indexVariable). app("++")
        current app(") {"). tab()
        for(stat in foreach body) {
            writeLine(stat)
        }
        current untab(). nl(). app("}")
    }

    write: static func ~_match (this: Skeleton, mat: Match) {
        isFirst := true
        cazes := mat cases
        writeBody := func(caze: Case) {
            current app("{"). tab()
            for (stat in caze getBody()) writeLine(stat)
            current untab(). nl(). app("}")
        }
        
        // `case =>` as only match-case
        if (cazes getSize() == 1) {
            caze := cazes get(0)
            if (!caze getExpr()) {                 
                writeBody(caze)
                return
            }
        }
         
        // sort is the wrong term, it basically puts the `case =>` at the end
        cazes sort(|x, y| 
            if (!x expr && y expr) return true
                return false
        )

        catchAlls := cazes filter(|x| !x expr) getSize()
        currentCatchAll := 1

        for(caze in mat getCases()) {
            if(!isFirst) current app(" else ")

            if(!caze getExpr()) {
                if(currentCatchAll < catchAlls) current app("if (true) ")
                currentCatchAll += 1
            } else {
                current app("if ("). app(caze getExpr()). app(")")
            }

            writeBody(caze)
            if(isFirst) isFirst = false;
        }
    }

}

