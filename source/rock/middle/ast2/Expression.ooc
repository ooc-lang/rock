

import Statement, Type

Expression: abstract class extends Statement {

    type: Type {
        get {
            getType()
        }
    }

    /** to be implemented by subclassing fuckers */
    getType: abstract func -> Type

}
