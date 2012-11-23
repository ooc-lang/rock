import structs/List
import os/Terminal

/**
    A generic List implementation that provides a circular list
    of doubly-linked nodes.

    :author: eagle2com
    :author: Noel Cower (Nilium)
 */
getchar: extern func

LinkedList: class <T> extends List<T> {
    _size = 0 : SizeT
    
    size : SizeT {
    	get {
    		_size
    	}
    }
    
    head: Node<T>

    init: func {
        head = Node<T> new()
        head prev = head
        head next = head
    }

    /** Adds a node containing `data` to the end of the list */
    add: func (data: T) {
        node := Node<T> new(head prev, head, data)
        head prev next = node
        head prev = node
        _size += 1
    }

    /**
        Adds a node containing `data` at the specified `index`, pushing
        nodes that follow it forward.

        Throws an exception when the index is less than zero or greater
        than the size of the list.
    */
    add: func ~withIndex(index: SSizeT, data: T) {
        if(index > 0 && index <= lastIndex()) {
			prevNode := getNode(index - 1)
			nextNode := prevNode next
			node := Node<T> new(prevNode,nextNode,data)
			prevNode next = node
			nextNode prev = node
			_size += 1
		} else if(index > 0 && index == _size) {
			add(data)
		} else if (index == 0) {
			node := Node<T> new(head,head next,data)
			head next prev = node
			head next = node
			_size += 1
		} else {
			Exception new(This, "Check index: 0 <= " + index toString() + " < " + size toString()) throw()
		}
    }

    /**
        Gets the value of the node stored at the specified index.

        Throws an exception when the index is out of range.
    */
    get: func(index: SSizeT) -> T {
		return getNode(index) data
	}

	/**
	    Gets the node at the specified index.

	    Throws an exception when the index is out of range.
	*/
    getNode: func(index: SSizeT) -> Node<T> {
		if(index < 0 || index >= _size) {
			Exception new(This, "Check index: 0 <= " + index toString() + " < " + size toString()) throw()
		}

		i = 0 : Int
		current := head next
		while(current next != head && i < index) {
			current = current next
			i += 1
		}
		return current
	}

	/**
	    Clears the contents of the list.
	*/
	clear: func {
	    head next = head
	    head prev = head
        _size = 0
	}

	/**
	    Returns the first index containing the `data`.
	*/
	indexOf: func (data: T) -> SSizeT {
		current := head next
		i := 0
		while(current != head) {
			if(memcmp(current data, data, T size) == 0){
				return i
			}
			i += 1
			current = current next
		}
		return -1
	}

	/**
	    Returns the last index containing the `data`.
	*/
	lastIndexOf: func (data: T) -> SSizeT {
		current := head prev
		i := _size - 1
		while(current != head) {
			if(memcmp(current data, data, T size) == 0){
				return i
			}
			i -= 1
			current = current prev
		}
		return -1
	}

	/**
	    Returns the first item in the list, or `null` if the list is empty.
	*/
	first: func -> T {
	    if (head next != head)
	        return head next data
	    else
	        return null
	}

	/**
	    Returns the last item in the list, or `null` if the list is empty.
	*/
	last: func -> T {
		if(head prev != head)
			return head prev data
		else
			return null
	}

	/**
	    Removes the node at the specified index.

	    Throws an exception when the index is out of range.
	*/
	removeAt: func (index: SSizeT) -> T {
		if(head next != head && 0 <= index && index < _size) {
			toRemove := getNode(index)
			removeNode(toRemove)
			return toRemove data
		}
		Exception new(This, "Check index: 0 <= " + index toString() + " < " + size toString()) throw()
	}

	/**
	    Removes the first instance of `data` from the list.

	    Returns true if successful and false if not.
	*/
	remove: func (data: T) -> Bool {
		i := indexOf(data)
		if(i != -1) {
			removeAt(i)
			return true
		}
		return false
	}

	/**
	    Removes the specified node from the list.
	*/
	removeNode: func(toRemove: Node<T>) {
		toRemove prev next = toRemove next
		toRemove next prev = toRemove prev
		toRemove prev = null
		toRemove next = null
        _size -= 1
	}

	/**
	    Removes the last node in the list.

	    Returns true if the last node was removed, false if the
	    list is empty.
	*/
	removeLast: func -> Bool {
		if(head prev != head) {
			removeNode(head prev)
			return true
		}
		return false
	}

	/**
	    Sets the value at the index specified.

	    The previous value is returned.

	    Throws an exception if the index is out of range.
	*/
	set: func (index: SSizeT, data: T) -> T {
		node := getNode(index)
		ret := node data
		node data = data
        return ret
    }

	/**
	    Returns the size of the list.
	*/
	getSize: func -> SSizeT { _size }

	/**
	    Returns an Iterator pointing to the front of the list.
	*/
	iterator: func -> LinkedListIterator<T> {
		LinkedListIterator new(this)
	}

	/**
	    Returns an Iterator pointing to the back of the list.
	*/
	backIterator: func -> LinkedListIterator<T> {
	    iter := LinkedListIterator new(this)
	    iter current = head prev
	    return iter
	}

	/**
	    Clones the list.
	*/
	clone: func -> This<T> {
	    list := This<T> new()
        if (head next != head) {
    	    iter := iterator()
    	    while (iter hasNext?())
    	        list add(iter next())
        }
	    return list
	}

    emptyClone: func <K> -> This<K> {
        This<K> new()
    }
}


/**
    Container type for the `LinkedList` class.
*/
Node: class <T>{

	/** The previous node in the list. */
	prev: Node<T>
	/** The next node in the list. */
	next: Node<T>
	/** The data contained by the node. */
	data: T

	init: func {
	}

	/** Initializes the node with previous and next nodes and data. */
	init: func ~withParams(=prev, =next, =data) {}

}

LinkedListIterator: class <T> extends BackIterator<T>  {

	current: Node<T>
	list: LinkedList<T>

	init: func ~ll (=list) {
		current = list head
	}

	hasNext?: func -> Bool {
		return (current next != list head)
	}

	next: func -> T {
		current = current next
		return current data
	}

    hasPrev?: func -> Bool {
        return (current != list head)
    }

    prev: func -> T {
        last := current
        current = current prev
        return last data
    }

    remove: func -> Bool {
        if (current == list head) {
            return false
        }

        old := current
        if(hasNext?()) {
            current = current next
        } else {
            current = current prev
        }
        list removeNode(old)
        return true
    }

}


operator [] <T>(list: LinkedList<T>,index: Int) -> T {return list get(index)}
