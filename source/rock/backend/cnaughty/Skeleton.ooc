import AwesomeWriter, ../../middle/[Visitor, Statement, ControlStatement]
import text/EscapeSequence, rock/frontend/BuildParams, io/File

Skeleton: abstract class extends Visitor {

    STRING_CONSTRUCTOR := static const "(void*) lang_String__makeStringLiteral(\"%s\", %d)"

    params: BuildParams
    module: Module

    hw, cw, fw, current: AwesomeWriter

    /** Write a line */
    writeLine: func (stat: Statement) {
        if(params debug?() && params lineDirectives) {
            if(!stat token module) stat token module = module

            current nl(). app("#line "). app(stat token getLineNumber() toString()). app(" \""). app(EscapeSequence escape(stat token getPath())). app("\"")
        }

        current nl(). app(stat)
        if(!stat instanceOf?(ControlStatement))
            current app(';')
    }

    writeStringLiteral: func (value: String, raw?: Bool = false) {
        if(raw?) {
            current app('"'). app(value). app('"')
        } else {
            current app(STRING_CONSTRUCTOR format(value, EscapeSequence unescape(value) length()))
        }
    }

    writeGcInit: func { 
        current nl(). app("#ifdef __ANDROID__");
        current nl(). app("GC_init();")
        current nl(). app("#else");
        current nl(). app("GC_INIT();")
        current nl(). app("#endif")
    }

}
