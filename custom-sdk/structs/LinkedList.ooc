import structs/List
import os/Terminal

/** 
 * LinkedList, not tested, use at your own risk!
 * @author eagle2com
 */
getchar: extern func
	
LinkedList: class <T> extends List<T> {
	
	size = 0 : Int
	first: Node<T>
	last: Node<T>
	
	init: func ~ll {
		first = null
		last = null
	}
	
	add: func (data: T) {
		node: Node<T>
		if(first) {
			node = Node<T> new(last,null,data)
			last next = node
		} else {
			node = Node<T> new(null,null,data)
			first = node
		}
		last = node
		size += 1
	}
	
	add: func ~withIndex(index: Int, data: T) {
		if(index > 0 && index <= lastIndex()) {
			prevNode := getNode(index - 1)
			nextNode := prevNode next
			node := Node<T> new(prevNode,nextNode,data)
			prevNode next = node
			nextNode prev = node
			size += 1
		} else if(index > 0 && index == size()) {
			add(data)
		} else if (index == 0) {
			node := Node<T> new(null,first,data)
			if(first) {
				first prev = node
				first = node
			} else {
				first = node
				last = node
			}
			size += 1
		} else {
			Exception new(This, "Check index: 0 <= " + index + " < " + size) throw()
		}
	}
	
	clear: func {
		current := first
		first = null
		while( current ) {
			next := current next
			current next = null
			current prev = null
			current = next
		}
		last = null
		size = 0
	}
	
	get: func(index: Int) -> T {
		return getNode(index) data
	}
	
	getNode: func(index: Int) -> Node<T> {
		if(index < 0 || index >= size) {
			Exception new(This, "Check index: 0 <= " + index + " < " + size) throw()
		}
		
		i = 0 : Int
		current := first
		while(current next != null && i < index) {
			current = current next
			i += 1
		}
		return current
	}
	
	indexOf: func (data: T) -> Int {
		current := first
		i := 0
		while(current) {
			if(current data == data){
				return i
			}
			i += 1
			current = current next
		}
		return -1
	}
	
	lastIndexOf: func (data: T) -> Int {
		current := last
		i := size - 1
		while(current) {
			if(current data == data){
				return i
			}
			i -= 1
			current = current prev
		}
		return -1
	}
	
	removeAt: func (index: Int) -> T {
		if(first != null && index >= 0 && index < size) {
			toRemove := getNode(index)
			if(toRemove next) {
				toRemove next prev = toRemove prev
			} else {
				last = toRemove prev
				if(toRemove prev) {
					toRemove prev next = null
				}
			}
			
			if(toRemove prev) {
				toRemove prev next = toRemove next
			} else {
				first = toRemove next
				if(toRemove next) {
					toRemove next prev = null
				}
			}
			size -= 1
			return toRemove data
		} //else {
			Exception new(This, "Check index: 0 <= " + index + " < " + size) throw()
		//}
	}
	
	remove: func (data: T) -> Bool {
		i := indexOf(data)
		if(i != -1) {
			removeAt(i)
			return true
		}			
		return false
	}
	
	removeNode: func(toRemove: Node<T>) -> Bool {
		if(toRemove next) {
            toRemove next prev = toRemove prev
        } else {
            last = toRemove prev
            if(toRemove prev) {
                toRemove prev next = null
            }
        }
        
        if(toRemove prev) {
            toRemove prev next = toRemove next
        } else {
            first = toRemove next
            if(toRemove next) {
                toRemove next prev = null
            }
        }
        size -= 1
        return true // FIXME: probably not right.
	}
	
	set: func (index: Int, data: T) -> T {
        // FIXME: stub
        return null
    }
	
	size: func -> Int {return size}
	
	iterator: func -> LinkedListIterator<T> {
		LinkedListIterator new(this)
	}
	
	clone: func -> LinkedList<T> {return 0}
	
	
	print: func {
		println()
		printf("prev: ")
		current := first
		while(current) {
			if(current prev) {
				Terminal setFgColor(Color red + current prev as Int % 7)
				printf("|%p|", current prev)
				Terminal reset()
			}
			else
				printf("|         |")
			current = current next
		}
		println()
		
		printf("this: ")
		current = first
		while(current) {	
			Terminal setFgColor(Color red + current as Int % 7)
			printf("|%p|", current)
			Terminal reset()
			current = current next
		}
		println()
		
		printf("next: ")
		current = first
		while(current) {
			if(current next) {
				Terminal setFgColor(Color red + current next as Int % 7)
				printf("|%p|", current next)
				Terminal reset()
			}
			else
				printf("|         |")
			current = current next
		}
		println()
	}
} 



Node: class <T>{
	
	prev: Node<T>
	next: Node<T>
	data: T
	
	init: func {
	}
	
	init: func ~withParams(=prev, =next, =data) {}
	
}

LinkedListIterator: class <T> extends Iterator<T>  {
	
	current: Node<T>
	list: LinkedList<T>
	
	init: func ~ll (=list) {
		current = list first
	}
	
	hasNext: func -> Bool {
		return (current != null)
	}
	 
	next: func -> T {
		prev := current
		current = current next
		return prev data
	}
	
    hasPrev: func -> Bool {
        return (current != null && current prev != null)
    }
    
    prev: func -> T {
        current = current prev
        return current data
    }
    
    remove: func -> Bool {
        old := current
        if(current next) {
            current = current next
        } else {
            current = current prev
        }
        return list removeNode(old)
    }
	
}


operator [] <T>(list: LinkedList<T>,index: Int) -> T {return list get(index)}
