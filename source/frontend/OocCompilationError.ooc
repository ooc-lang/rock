import CompilationFailedError

/*
OocCompilationError: class extends CompilationFailedError {

	init: func (node: Node, stack: NodeList<Node>, message: String) {
		this(node startToken, stack getModule(), message)
	}
	
	init: func (node: Node, module: Module, message: String) {
		this(node startToken, module, message)
	}
	
	init: func (startToken: Token, stack: NodeList<Node>, message: String) {
		this(startToken, stack getModule(), message)
	}
	
	init: func (startToken: Token, module: Module, message: String) {
		super(module getReader() getLocation(startToken), "[ERROR] " + message)
	}

}
*/
