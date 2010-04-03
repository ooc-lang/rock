import structs/ArrayList
import BinarySeq

tmp := gc_malloc(3) as UChar*

tmp[0] = 0x55
PUSH_EBP := static const BinarySeq new(1, tmp) 

tmp[0] = 0x6a
PUSH_BYTE := static const BinarySeq new(1, tmp) 

tmp[0] = 0x66
tmp[1] = 0x68
PUSH_WORD := static const BinarySeq new(2, tmp)

tmp[0] = 0x68
PUSH_DWORD := static const BinarySeq new(1, tmp)

tmp[0] = 0x66
tmp[1] = 0xff
tmp[2] = 0x75
PUSHW_EBP_VAL := static const BinarySeq new(3, tmp)

tmp[0] = 0xff
tmp[1] = 0x75
PUSHDW_EBP_VAL := static const BinarySeq new(2, tmp)

tmp[0] = 0x89
tmp[1] = 0xe5
MOV_EBP_ESP := static const BinarySeq new(2, tmp) 

tmp[0] = 0xbb
MOV_EBX_ADDRESS := static const BinarySeq new(1, tmp)

tmp[0] = 0x8b
tmp[1] = 0x5d
tmp[2] = 0x08
MOV_EBX_EBP_PLUS_8 := static const BinarySeq new(3, tmp)

tmp[0] = 0x53
PUSH_EBX := static const BinarySeq new(1, tmp)

tmp[0] = 0x68
PUSH_ADDRESS := static const BinarySeq new(1, tmp)

tmp[0] = 0xe8
CALL_ADDRESS := static const BinarySeq new(1, tmp)

tmp[0] = 0xff
tmp[1] = 0xd3
CALL_EBX := static const BinarySeq new(2, tmp)

tmp[0] = 0xc9
LEAVE := static const BinarySeq new(1, tmp)

tmp[0] = 0xc3
RET := static const BinarySeq new(1, tmp)

//OpCodes: class  {
    
//    }
/*
Partial: class {
    
    funcPtr: Func
    argSizes := ""
    bseq: BinarySeq
    init: func(=funcPtr) {initSequence(1024)}
    
    getBase: func(argSizes: String, bseq: BinarySeq) -> Int{
        base := 0x04
        for (c: Char in argSizes) {
            base = base + bseq transTable get(String new(c))
        }
    return base
    }
    
    pushNonClosureArgs: func(base: Int)  {
        for (c: Char in argSizes) {
            s := String new(c)
            OpCodes pushCallerArg(bseq, op transTable[s])
            bseq append(base& as UChar*, UChar size)
            base = base - bseq transTable get(s) //op transTable get(s)
        }
        printf("EndBase: %d\n", base)
        "pushNonClosureArgs: " println()
        bseq print()
        "" println()
    }
   
    initSequence: func(s: Int) -> BinarySeq {
        bseq = BinarySeq new(s)
        bseq append(OpCodes PUSH_EBP)
        bseq append(OpCodes MOV_EBP_ESP)
        "Init sequence: " print()
        bseq print()
        "" println()
        return bseq
    }

    
    
}
*/
