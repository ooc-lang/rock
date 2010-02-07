/* lang/types header file, generated with rock, the ooc compiler written in ooc */

#ifndef __lang_types__
#define __lang_types__

#include "types-fwd.h"

struct _lang__Object {
    
    lang__Class* class;
};


struct _lang__Class {
    struct _lang__Object __super__;
    lang__SizeT instanceSize;
    lang__SizeT size;
    lang__String name;
    lang__Class* super;
};


struct _lang__None {
    struct _lang__Object __super__;
};


struct _lang__Range {
    lang__Int min;
    lang__Int max;
};

struct _lang__Exception {
    struct _lang__Object __super__;
    lang__Class* origin;
    lang__String msg;
};


struct _lang__ObjectClass {
    struct _lang__Class __super__;
    void (*__defaults__)(lang__Object*);
    void (*__destroy__)(lang__Object*);
    lang__Bool (*instanceOf)(lang__Object*, lang__Class*);
};


struct _lang__ClassClass {
    struct _lang__ObjectClass __super__;
    lang__Object* (*alloc)(lang__Class*);
    lang__Bool (*inheritsFrom)(lang__Class*, lang__Class*);
};


struct _lang__NoneClass {
    struct _lang__ClassClass __super__;
    lang__None* (*new)();
    void (*init)(lang__None*);
};


struct _lang__VoidClass {
    struct _lang__ClassClass __super__;
};


struct _lang__PointerClass {
    struct _lang__ClassClass __super__;
    lang__String (*toString)(lang__Pointer);
};


struct _lang__CharClass {
    struct _lang__ClassClass __super__;
    lang__Bool (*isAlphaNumeric)(lang__Char);
    lang__Bool (*isAlpha)(lang__Char);
    lang__Bool (*isLower)(lang__Char);
    lang__Bool (*isUpper)(lang__Char);
    lang__Bool (*isDigit)(lang__Char);
    lang__Bool (*isHexDigit)(lang__Char);
    lang__Bool (*isControl)(lang__Char);
    lang__Bool (*isGraph)(lang__Char);
    lang__Bool (*isPrintable)(lang__Char);
    lang__Bool (*isPunctuation)(lang__Char);
    lang__Bool (*isWhitespace)(lang__Char);
    lang__Bool (*isBlank)(lang__Char);
    lang__Int (*toInt)(lang__Char);
    lang__Char (*toLower)(lang__Char);
    lang__Char (*toUpper)(lang__Char);
    void (*print)(lang__Char);
    void (*println)(lang__Char);
};


struct _lang__SCharClass {
    struct _lang__CharClass __super__;
};


struct _lang__UCharClass {
    struct _lang__CharClass __super__;
};


struct _lang__WCharClass {
    struct _lang__ClassClass __super__;
};


struct _lang__StringClass {
    struct _lang__ClassClass __super__;
    lang__Int (*toInt)(lang__String);
    lang__Long (*toLong)(lang__String);
    lang__LLong (*toLLong)(lang__String);
    lang__Double (*toDouble)(lang__String);
    lang__Float (*toFloat)(lang__String);
    lang__SizeT (*first)(lang__String);
    lang__SizeT (*lastIndex)(lang__String);
    lang__Char (*last)(lang__String);
    void (*println)(lang__String);
    lang__SizeT (*length)(lang__String);
    lang__String (*append)(lang__String, lang__String);
    lang__String (*prepend)(lang__String, lang__String);
    lang__String (*format)(lang__String, ...);
};


struct _lang__LLongClass {
    struct _lang__ClassClass __super__;
    lang__String (*toString)(lang__LLong);
    lang__String (*toHexString)(lang__LLong);
    lang__Bool (*isOdd)(lang__LLong);
    lang__Bool (*isEven)(lang__LLong);
    lang__Bool (*in)(lang__LLong, lang__Range);
};


struct _lang__LongClass {
    struct _lang__LLongClass __super__;
};


struct _lang__ShortClass {
    struct _lang__LLongClass __super__;
};


struct _lang__IntClass {
    struct _lang__LLongClass __super__;
};


struct _lang__ULLongClass {
    struct _lang__LLongClass __super__;
};


struct _lang__ULongClass {
    struct _lang__ULLongClass __super__;
};


struct _lang__UIntClass {
    struct _lang__ULLongClass __super__;
};


struct _lang__UShortClass {
    struct _lang__ULLongClass __super__;
};


struct _lang__Int8Class {
    struct _lang__LLongClass __super__;
};


struct _lang__Int16Class {
    struct _lang__LLongClass __super__;
};


struct _lang__Int32Class {
    struct _lang__LLongClass __super__;
};


struct _lang__Int64Class {
    struct _lang__LLongClass __super__;
};


struct _lang__UInt8Class {
    struct _lang__ULLongClass __super__;
};


struct _lang__UInt16Class {
    struct _lang__ULLongClass __super__;
};


struct _lang__UInt32Class {
    struct _lang__ULLongClass __super__;
};


struct _lang__UInt64Class {
    struct _lang__ULLongClass __super__;
};


struct _lang__OctetClass {
    struct _lang__ClassClass __super__;
};


struct _lang__SizeTClass {
    struct _lang__LLongClass __super__;
};


struct _lang__BoolClass {
    struct _lang__ClassClass __super__;
    lang__String (*toString)(lang__Bool);
};


struct _lang__LDoubleClass {
    struct _lang__ClassClass __super__;
};


struct _lang__DoubleClass {
    struct _lang__LDoubleClass __super__;
};


struct _lang__FloatClass {
    struct _lang__LDoubleClass __super__;
};


struct _lang__RangeClass {
    struct _lang__ClassClass __super__;
    lang__Range (*new)(lang__Int, lang__Int);
};


struct _lang__ExceptionClass {
    struct _lang__ClassClass __super__;
    lang__Exception* (*new_originMsg)(lang__Class*, lang__String);
    void (*init_originMsg)(lang__Exception*, lang__Class*, lang__String);
    lang__Exception* (*new_noOrigin)(lang__String);
    void (*init_noOrigin)(lang__Exception*, lang__String);
    void (*crash)(lang__Exception*);
    lang__String (*getMessage)(lang__Exception*);
    void (*print)(lang__Exception*);
    void (*throw)(lang__Exception*);
};


lang__String __OP_ADD_String_String__String(lang__String left, lang__String right);

#endif // __lang_types__
