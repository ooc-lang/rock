import structs/ArrayList
import BinarySeq
import OpCodes into OpCodes

Partial: class {     
    
    bseq: BinarySeq

    arguments := ArrayList<Cell<Pointer>> new()
    
    init: func {
        init(1024)
    }
    
    init: func ~withSize(size: Int) {
        initSequence(size)
    }
    
    initSequence: func(size: Int) -> BinarySeq {
        bseq = BinarySeq new(size)
        bseq append(OpCodes PUSH_EBP)
        bseq append(OpCodes MOV_EBP_ESP)
        return bseq
    }
    
    pushClosureArg: func <T> (arg: T) {
        if     (T size == 1) { bseq append(OpCodes PUSH_BYTE) }
        elseif (T size == 2) { bseq append(OpCodes PUSH_WORD) }
        elseif (T size == 4) { bseq append(OpCodes PUSH_DWORD) }
        else { 
            fprintf(stderr, "Trying to push unknown size: %d\n", T size)
            x := 0
            x = 10 / x // dirty way of throwing an exception
        }
        /*
        match T size {
            case 1 => bseq append(OpCodes PUSH_BYTE)
            case 2 => bseq append(OpCodes PUSH_WORD)
            case 4 => bseq append(OpCodes PUSH_DWORD)
            case => {        }
        */
        bseq append((arg&) as Pointer, T size)
    }

    pushCallerArg: func <T> (arg: T) {
        if (T size == 1 || T size == 2) { bseq append(OpCodes PUSHW_EBP_VAL) }
        elseif (T size == 4) { bseq append(OpCodes PUSHDW_EBP_VAL) }
        else {
            fprintf(stderr, "Trying to push unknown size: %d\n", T size)
            x := 0
            x = 10 / x // dirty way of throwing an exception
        }
        /*
        match T size {
            case 1 || 2 => bseq += OpCodes PUSHW_EBP_VAL
            case 4 => bseq += OpCodes PUSHDW_EBP_VAL
            case =>{fprintf(stderr, "Trying to push unknown size: %d\n", T size)
                 x := 0
                 x = 10 / x // dirty way of throwing an exception
                }
        }
        */ 
    }
    
    addArgument: func<T> (param: T) {
        arg := Cell<T> new(param)
        arguments add(arg)
    }
    
    genCode: func <T> (function: Func, closureArg: T, argSizes: String) -> Func {
        pushNonClosureArgs(getBase(argSizes, bseq), argSizes)
        pushClosureArg(closureArg)
        finishSequence(function)
        bseq print()
        return bseq data as Func
    }
    
    genCode: func ~multipleArgs(function: Func, argSizes: String) -> Func { 
        // IMPORTANT!! bug concerning choice of right polymorphic func
        // even if a non-closure arg is smaller than 4 byte
        // treating it as it'd have 4 bytes works
        // should be fixed later on, but it's currently
        // more important to have somehing working :) 
        arguments reverse()
        pushNonClosureArgs(getBase(argSizes, bseq), argSizes)
        for (item: Cell<Pointer> in arguments) {
            pushClosureArg(item val as Pointer)
        } 
        finishSequence(function)
        /*
        printf("Code = ")
        bseq print()
        */
        return bseq data as Func
    }
    
    pushNonClosureArgs: func(base: UChar, argSizes: String)  {
        //for (c: Char in argSizes) {
        for(i in 0..argSizes length()) {
            c := argSizes[i]
            s := String new(c)
            pushCallerArg(bseq transTable get(s))
            bseq append((base&) as Pointer, 1)
            base = base as Int - bseq transTable get(s)
        }
        /*
        printf("EndBase: %d\n", base)
        "pushNonClosureArgs: " println()
        bseq print()
        "" println()
        */
    }

    finishSequence: func(funcPtr: Func) {
        // Directly calling the address (method 1)
        // causes a segfault *before* calling the function.
        // No idea why - with an extern nasm module it works fine
        
        // Copying the address to EBX causes a segfault after
        // calling the function. This behaviour is consistent with nasm
        
        // Copying the address to EAX seems to work =)
        
        //bseq append(OpCodes CALL_ADDRESS)
        //bseq append((funcPtr&) as UInt8*, Pointer size)
        
        //bseq append(OpCodes MOV_EBX_ADDRESS)
        //bseq append((funcPtr&) as UInt8*, Pointer size)
        //bseq append(OpCodes CALL_EBX)
        
        bseq append(OpCodes MOV_EAX_ADDRESS)
        bseq append((funcPtr&) as Pointer, Pointer size)
        bseq append(OpCodes CALL_EAX)
        
        bseq append(OpCodes LEAVE)
        bseq append(OpCodes RET)
        //bseq append(OpCodes NOP)
        //bseq append(OpCodes NOP)
        //bseq append(OpCodes NOP)
        //bseq append(OpCodes NOP)
    }
    /*
    converseFloat: static func(f: Float) -> Int {
        (f& as Int32*)@
    }
    */
    
    getBase: func(argSizes: String, bseq: BinarySeq) -> UChar {
        base := 0x04 as Int
        //for (c: Char in argSizes) {
        for(i in 0..argSizes length()) {
            c := argSizes[i]
            base = base + bseq transTable get(String new(c))
        }
        return base as UChar
    }
}

