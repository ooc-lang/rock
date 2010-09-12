import Trail
import ../../frontend/[CommandLine, Token, BuildParams]
import ../Node

/**
 * Handle errors and warnings from the compiler
 *
 * @author Amos Wenger (nddrylliog)
 */

ErrorHandler: interface {

    onError: func (e: Error)

}

DevNullErrorHandler: class implements ErrorHandler {
    onError: func (e: Error) { /* To the bit bucket! */ }
}

DefaultErrorHandler: class implements ErrorHandler {

    params: BuildParams

    init: func ~withParams (=params) {}

    onError: func (e: Error) {
        e format() println()
        if(e fatal?() && params fatalError) {
            CommandLine failure(params)
        }
    }

}

/**
 * An error thrown.
 *
 * Note: in an ideal world, we'd have a nice class hierarchy so
 * we can filter out errors and have re
 *
 * @author Amos Wenger (nddrylliog)
 */

Error: abstract class {

    token: Token
    message: String

    init: func ~tokenMessage (=token, =message) {}

    fatal?: func -> Bool { true }

    format: func -> String { token formatMessage(message, "ERROR") }

}

InternalError: class extends Error {

    init: super func ~tokenMessage

}

Warning: class extends Error {

    init: super func ~tokenMessage
    fatal?: func -> Bool { false }

    format: func -> String { token formatMessage(message, "WARNING") }

}

/*
 * A small collection of often-used internal errors:
 */

CouldntAdd: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add a " + newcomer toString() + " before a " + mark toString() + ", trail = " + trail toString())
    }

}

CouldntAddBefore: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add a " + newcomer toString() + " before a " + mark toString() + ", trail = " + trail toString())
    }

}

CouldntAddAfter: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add a " + newcomer toString() + " after a " + mark toString() + ", trail = " + trail toString())
    }

}

CouldntAddBeforeInScope: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add " + newcomer toString() + " before " + mark toString() + " in scope. trail = " + trail toString())
    }

}

CouldntAddAfterInScope: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add " + newcomer toString() + " after " + mark toString() + " in scope. trail = " + trail toString())
    }

}

CouldntReplace: class extends InternalError {

    oldie, kiddo: Node

    init: func (.token, =oldie, =kiddo, trail: Trail) {
        super(token, "Couldn't replace " + oldie toString() + " with " + kiddo toString() + ", trail = " + trail toString())
    }

}





