
//////////////////// Generated code //////////////////////

File: class {

    open : static func (name: String, exception : Exception@) -> This {
        
        // oh there's a problem
        exception = Exception new(This, "Omg it doesn't work") 
        return null
        
        // if everything goes fine
        exception = null
        return new()
        
    }

}


main: func {

    exception : Exception
    f := File open(name, exception&)
    if(exception) {
        // handle the situation
    }
    
    // continue

}




///////////////////// Upcoming syntax //////////////////////


File: class {

    // the thrown exception type could probably be inferred
    // but for a first impl, it doesn't hurt to require it
    open: static func (name: String) throws Exception -> This {
    
        // oh there's a problem
        Exception new(This, "Omg it doesn't work") throw()
        
        // if everything goes fine
        return new()
    
    }

}

main: func {

    try {
        f := File open(name)
    } catch(Exception) {
        // handle the situation
    }
    
    // continue

}


