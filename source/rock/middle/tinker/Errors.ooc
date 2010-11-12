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
        super(token, "Couldn't add a %s before a %s, trail = %s" format(newcomer toString(), mark toString(), trail toString()))
    }

}

CouldntAddBefore: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add %s before %s. trail = %s" format(newcomer toString(), mark toString(), trail toString()))
    }

}

CouldntAddAfter: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add %s after %s. trail = %s" format(newcomer toString(), mark toString(), trail toString()))
    }

}

CouldntAddBeforeInScope: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add %s before %s in scope. trail = %s" format(newcomer toString(), mark toString(), trail toString()))
    }

}

CouldntAddAfterInScope: class extends InternalError {

    mark, newcomer: Node

    init: func (.token, =mark, =newcomer, trail: Trail) {
        super(token, "Couldn't add %s after %s in scope. trail = %s" format(newcomer toString(), mark toString(), trail toString()))
    }

}

CouldntReplace: class extends InternalError {

    oldie, kiddo: Node

    init: func (.token, =oldie, =kiddo, trail: Trail) {
        super(token, "Couldn't replace %s with %s, trail = %s" format(oldie toString(), kiddo toString(), trail toString()))
    }

}





