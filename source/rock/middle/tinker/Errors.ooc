import Trail, Token
import ../../frontend/CommandLine // for fail()

/**
 * Handle errors and warnings from the compiler
 *
 * @author Amos Wenger (nddrylliog)
 */

ErrorHandler: interface {

    onError: func (e: Error)

}

DefaultErrorhandler: class implements ErrorHandler {

    params: BuildParams

    init: func (=params) {}

    onError: func (e: Error) {
        e format() println()
        if(e isFatal?() && params fatalError) {
            CommandLine failure()
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

    isFatal?: func -> Bool { true }

    format: func -> String { token formatMessage(message, "ERROR") }

}

InternalError: class extends Error {

    init: super func ~tokenMessage

}

Warning: class extends Error {

    init: super func ~tokenMessage
    isFatal?: func -> Bool { false }

    format: func -> String { token formatMessage(message, "ERROR") }

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





