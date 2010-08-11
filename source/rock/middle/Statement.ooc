import ../frontend/Token
import Node

Statement: abstract class extends Node {

    init: func ~statement (.token) { super(token) }

    clone: abstract func -> This

}
