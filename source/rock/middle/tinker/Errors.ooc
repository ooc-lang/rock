import Token

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
        e token formatMessage(message, "[ERROR]") println()
        if(BuildParams fatalError) CommandLine failure()
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

    message: String
    token: Token

    init: func ~messageToken (=token, =message) {}

    isFatal: abstract func -> Bool {}

}

InternalError: class extends Error {

    init: super func ~messageToken
    isFatal: func -> Bool { true }

}

Warning: class extends Error {

    init: super func ~messageToken
    isFatal: func -> Bool { false }

}


