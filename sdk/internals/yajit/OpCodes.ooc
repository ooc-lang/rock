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

tmp[0] = 0xb8
MOV_EAX_ADDRESS := static const BinarySeq new(1, tmp)

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
tmp[1] = 0xd0
CALL_EAX := static const BinarySeq new(2, tmp)

tmp[0] = 0xff
tmp[1] = 0xd3
CALL_EBX := static const BinarySeq new(2, tmp)

tmp[0] = 0xc9
LEAVE := static const BinarySeq new(1, tmp)

tmp[0] = 0xc3
RET := static const BinarySeq new(1, tmp)

tmp[0] = 0x83
tmp[1] = 0xec
tmp[2] = 0x18
RESERVE_STACK_SPACE := static const BinarySeq new(3, tmp)

tmp[0] = 0x90
NOP := static const BinarySeq new(1, tmp)
