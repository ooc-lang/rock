import structs/List
import os/Terminal

/** 
 * LinkedList, not tested, use at your own risk!
 * @author eagle2com, Nilium
 */
getchar: extern func

LinkedList: class <T> extends List<T> {
    size = 0 : Int
    head: Node<T>
    
    init: func {
        head = Node<T> new()
        head prev = head
        head next = head
    }
    
    add: func (data: T) {
        node := Node<T> new(head prev, head, data)
        head prev next = node
        head prev = node
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
			node := Node<T> new(head,head next,data)
			head next prev = node
			head next = node
			size += 1
		} else {
			Exception new(This, "Check index: 0 <= " + index + " < " + size()) throw()
		}
    }
    
    get: func(index: Int) -> T {
		return getNode(index) data
	}
    
    getNode: func(index: Int) -> Node<T> {
		if(index < 0 || index >= size()) {
			Exception new(This, "Check index: 0 <= " + index + " < " + size()) throw()
		}
		
		i = 0 : Int
		current := head next
		while(current next != head && i < index) {
			current = current next
			i += 1
		}
		return current
	}
	
	clear: func {
	    head next = head
	    head prev = head
	}
	
	indexOf: func (data: T) -> Int {
		current := head next
		i := 0
		while(current != head) {
			if(current data == data){
				return i
			}
			i += 1
			current = current next
		}
		return -1
	}
	
	lastIndexOf: func (data: T) -> Int {
		current := head prev
		i := size() - 1
		while(current != head) {
			if(current data == data){
				return i
			}
			i -= 1
			current = current prev
		}
		return -1
	}
	
	first: func -> T {
	    if (head next != head)
	        return head next data
	    else
	        return null
	}
	
	last: func -> T {
		if(head prev != head)
			return head prev data
		else
			return null
	}
	
	removeAt: func (index: Int) -> T {
		if(head next != head && index >= 0 && index < size()) {
			toRemove := getNode(index)
			removeNode(toRemove)
			size -= 1
			return toRemove data
		} //else {
			Exception new(This, "Check index: 0 <= " + index + " < " + size()) throw()
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
	
	removeNode: func(toRemove: Node<T>) {
		toRemove prev next = toRemove next
		toRemove next prev = toRemove prev
		toRemove prev = null
		toRemove next = null
        size -= 1
	}
	
	removeLast: func -> Bool {
		if(head prev != head) {
			removeNode(head prev)
			return true
		}
		return false
	}
	
	set: func (index: Int, data: T) -> T {
		node := getNode(index)
		ret := node data
		node data = data
        return ret
    }
	
	size: func -> Int {return size}
	
	iterator: func -> LinkedListIterator<T> {
		LinkedListIterator new(this)
	}
	
	back: func -> LinkedListIterator<T> {
	    iter := LinkedListIterator new(this)
	    iter current = head prev
	    return iter
	}
	
	clone: func -> This<T> {
	    list := This<T> new()
        if (head next != head) {
    	    iter := front()
    	    while (iter hasNext())
    	        list add(iter next())
        }
	    return list
	}
	
	print: func {
		println()
		printf("prev: ")
		current := head next
		while(current != head) {
			if(current prev) {
				Terminal setFgColor(Color red + current prev as SizeT % 7)
				printf("|%p|", current prev)
				Terminal reset()
			}
			else
				printf("|         |")
			current = current next
		}
		println()
		
		printf("this: ")
		current = head next
		while(current != head) {	
			Terminal setFgColor(Color red + current as SizeT % 7)
			printf("|%p|", current)
			Terminal reset()
			current = current next
		}
		println()
		
		printf("next: ")
		current = head next
		while(current != head) {
			if(current next) {
				Terminal setFgColor(Color red + current next as SizeT % 7)
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
		current = list head
	}
	
	hasNext: func -> Bool {
		return (current next != list head)
	}
	 
	next: func -> T {
		current = current next
		return current data
	}
	
    hasPrev: func -> Bool {
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
        if(hasNext()) {
            current = current next
        } else {
            current = current prev
        }
        list removeNode(old)
        return true
    }
	
}


operator [] <T>(list: LinkedList<T>,index: Int) -> T {return list get(index)}
