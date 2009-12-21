import AwesomeWriter, ../middle/[Visitor, Statement, ControlStatement]

Skeleton: abstract class extends Visitor {
    
    hw, cw, fw, current: AwesomeWriter
    
    /** Write a line */
    writeLine: func (stat: Statement) {
        current nl(). app(stat)
        if(!stat instanceOf(ControlStatement))
            current app(';')
    }
    
}
