/* lang/types source file, generated with rock, the ooc compiler written in ooc */

#include "types.h"


void Object___defaults___impl(lang__Object* this) {
}

void Object___destroy___impl(lang__Object* this) {
}

lang__Bool Object_instanceOf(lang__Object* this, lang__Class* T) {
    return Class_inheritsFrom(this->class, T);
}

lang__ObjectClass *Object_class(){
    static lang__ObjectClass class = 
    {
        {
            .instanceSize = sizeof(lang__Object),
            .size = sizeof(void*),
            .name = "Object",
        },
        .__defaults__ = Object___defaults___impl,
        .__destroy__ = Object___destroy___impl,
    };
    return &class;
}

void Object___defaults__(lang__Object* this) {
    ((lang__ObjectClass *)((lang__Object *)this)->class)->__defaults__((lang__Object*)this);
}

void Object___destroy__(lang__Object* this) {
    ((lang__ObjectClass *)((lang__Object *)this)->class)->__destroy__((lang__Object*)this);
}

lang__Object* Class_alloc(lang__Class* this) {
    lang__Object* object = ((lang__Object*) GC_MALLOC(this->instanceSize));
    if (object) {
        object->class = this;
        Object___defaults__(object);
    }
    return object;
}

lang__Bool Class_inheritsFrom(lang__Class* this, lang__Class* T) {
    if (this == T) {
        return true;
    }
    return (this->super ? Class_inheritsFrom(this->super, T) : false);
}

lang__ClassClass *Class_class(){
    static lang__Bool __done__ = false;
    static lang__ClassClass class = 
    {
        {
            {
                .instanceSize = sizeof(lang__Class),
                .size = sizeof(void*),
                .name = "Class",
            },
            .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
            .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void None_init_impl(lang__None* this) {
}

lang__NoneClass *None_class(){
    static lang__Bool __done__ = false;
    static lang__NoneClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__None),
                    .size = sizeof(void*),
                    .name = "None",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
        .new = None_new,
        .init = None_init_impl,
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void None_init(lang__None* this) {
    ((lang__NoneClass *)((lang__Object *)this)->class)->init((lang__None*)this);
}
lang__None* None_new() {
    lang__None* this = ((lang__None*) Class_alloc((lang__Class*) None_class()));
    None_init(this);
    return this;
}

lang__VoidClass *Void_class(){
    static lang__Bool __done__ = false;
    static lang__VoidClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Void),
                    .size = sizeof(void*),
                    .name = "Void",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__String Pointer_toString(lang__Pointer this) {
    return String_format("%p", this);
}

lang__PointerClass *Pointer_class(){
    static lang__Bool __done__ = false;
    static lang__PointerClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Pointer),
                    .size = sizeof(void*),
                    .name = "Pointer",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__Bool Char_isAlphaNumeric(lang__Char this) {
    return Char_isAlpha(this) || Char_isDigit(this);
}

lang__Bool Char_isAlpha(lang__Char this) {
    return Char_isLower(this) || Char_isUpper(this);
}

lang__Bool Char_isLower(lang__Char this) {
    return this >= 'a' && this <= 'z';
}

lang__Bool Char_isUpper(lang__Char this) {
    return this >= 'A' && this <= 'Z';
}

lang__Bool Char_isDigit(lang__Char this) {
    return this >= '0' && this <= '9';
}

lang__Bool Char_isHexDigit(lang__Char this) {
    return Char_isDigit(this) || (this >= 'A' && this <= 'F') || (this >= 'a' && this <= 'f');
}

lang__Bool Char_isControl(lang__Char this) {
    return (this >= 0 && this <= 31) || this == 127;
}

lang__Bool Char_isGraph(lang__Char this) {
    return Char_isPrintable(this) && this != ' ';
}

lang__Bool Char_isPrintable(lang__Char this) {
    return this >= 32 && this <= 126;
}

lang__Bool Char_isPunctuation(lang__Char this) {
    return Char_isPrintable(this) && !Char_isAlphaNumeric(this) && this != ' ';
}

lang__Bool Char_isWhitespace(lang__Char this) {
    return this == ' ' || this == '\n' || this == '\r' || this == '\t' || this == '\f' || this == '\v';
}

lang__Bool Char_isBlank(lang__Char this) {
    return this == ' ' || this == '\t';
}

lang__Int Char_toInt(lang__Char this) {
    if (Char_isDigit(this)) {
        return (this - '0');
    }
    return -1;
}

void Char_print(lang__Char this) {
    printf("%c", this);
}

void Char_println(lang__Char this) {
    printf("%c\n", this);
}

lang__CharClass *Char_class(){
    static lang__Bool __done__ = false;
    static lang__CharClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Char),
                    .size = sizeof(void*),
                    .name = "Char",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__SCharClass *SChar_class(){
    static lang__Bool __done__ = false;
    static lang__SCharClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__SChar),
                        .size = sizeof(void*),
                        .name = "SChar",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Char_class();
        __done__ = true;
    }
    return &class;
}

lang__UCharClass *UChar_class(){
    static lang__Bool __done__ = false;
    static lang__UCharClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__UChar),
                        .size = sizeof(void*),
                        .name = "UChar",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Char_class();
        __done__ = true;
    }
    return &class;
}

lang__WCharClass *WChar_class(){
    static lang__Bool __done__ = false;
    static lang__WCharClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__WChar),
                    .size = sizeof(void*),
                    .name = "WChar",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__SizeT String_first(lang__String this) {
    return this[0];
}

lang__SizeT String_lastIndex(lang__String this) {
    return strlen(this) - 1;
}

lang__Char String_last(lang__String this) {
    return this[String_lastIndex(this)];
}

void String_println(lang__String this) {
    printf("%s\n", this);
}

lang__String String_append(lang__String this, lang__String other) {
    lang__SizeT length = strlen(this);
    lang__SizeT rlength = strlen((lang__String) other);
    lang__Char* copy = ((lang__Char*) GC_MALLOC(length + rlength + 1));
    memcpy(copy, this, length);
    memcpy(((lang__Char*) copy) + length, other, rlength + 1);
    return copy;
}

lang__String String_prepend(lang__String this, lang__String other) {
    return String_append((lang__String) other, this);
}

lang__String String_format(lang__String this, ...) {
    lang__VaList list;
    va_start(list, this);
    lang__Int length = vsnprintf(NULL, 0, this, list) + 1;
    lang__String output = GC_MALLOC(length);
    va_end(list);
    va_start(list, this);
    vsnprintf(output, length, this, list);
    va_end(list);
    return output;
}

lang__StringClass *String_class(){
    static lang__Bool __done__ = false;
    static lang__StringClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__String),
                    .size = sizeof(void*),
                    .name = "String",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__String LLong_toString(lang__LLong this) {
    return String_format("%lld", this);
}

lang__String LLong_toHexString(lang__LLong this) {
    return String_format("%llx", this);
}

lang__Bool LLong_isOdd(lang__LLong this) {
    return this % ((lang__LLong) 2) == 1;
}

lang__Bool LLong_isEven(lang__LLong this) {
    return this % ((lang__LLong) 2) == 0;
}

lang__Bool LLong_in(lang__LLong this, lang__Range range) {
    return this >= range.min && this < range.max;
}

lang__LLongClass *LLong_class(){
    static lang__Bool __done__ = false;
    static lang__LLongClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__LLong),
                    .size = sizeof(void*),
                    .name = "LLong",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__LongClass *Long_class(){
    static lang__Bool __done__ = false;
    static lang__LongClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Long),
                        .size = sizeof(void*),
                        .name = "Long",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__ShortClass *Short_class(){
    static lang__Bool __done__ = false;
    static lang__ShortClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Short),
                        .size = sizeof(void*),
                        .name = "Short",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__IntClass *Int_class(){
    static lang__Bool __done__ = false;
    static lang__IntClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Int),
                        .size = sizeof(void*),
                        .name = "Int",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__String ULLong_toString(lang__ULLong this) {
    return String_format("%llu", this);
}

lang__Bool ULLong_in(lang__ULLong this, lang__Range range) {
    return this >= range.min && this < range.max;
}

lang__ULLongClass *ULLong_class(){
    static lang__Bool __done__ = false;
    static lang__ULLongClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__ULLong),
                        .size = sizeof(void*),
                        .name = "ULLong",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__ULongClass *ULong_class(){
    static lang__Bool __done__ = false;
    static lang__ULongClass class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__ULong),
                            .size = sizeof(void*),
                            .name = "ULong",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UIntClass *UInt_class(){
    static lang__Bool __done__ = false;
    static lang__UIntClass class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UInt),
                            .size = sizeof(void*),
                            .name = "UInt",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UShortClass *UShort_class(){
    static lang__Bool __done__ = false;
    static lang__UShortClass class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UShort),
                            .size = sizeof(void*),
                            .name = "UShort",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__Int8Class *Int8_class(){
    static lang__Bool __done__ = false;
    static lang__Int8Class class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Int8),
                        .size = sizeof(void*),
                        .name = "Int8",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__Int16Class *Int16_class(){
    static lang__Bool __done__ = false;
    static lang__Int16Class class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Int16),
                        .size = sizeof(void*),
                        .name = "Int16",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__Int32Class *Int32_class(){
    static lang__Bool __done__ = false;
    static lang__Int32Class class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Int32),
                        .size = sizeof(void*),
                        .name = "Int32",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__Int64Class *Int64_class(){
    static lang__Bool __done__ = false;
    static lang__Int64Class class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Int64),
                        .size = sizeof(void*),
                        .name = "Int64",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UInt8Class *UInt8_class(){
    static lang__Bool __done__ = false;
    static lang__UInt8Class class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UInt8),
                            .size = sizeof(void*),
                            .name = "UInt8",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UInt16Class *UInt16_class(){
    static lang__Bool __done__ = false;
    static lang__UInt16Class class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UInt16),
                            .size = sizeof(void*),
                            .name = "UInt16",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UInt32Class *UInt32_class(){
    static lang__Bool __done__ = false;
    static lang__UInt32Class class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UInt32),
                            .size = sizeof(void*),
                            .name = "UInt32",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__UInt64Class *UInt64_class(){
    static lang__Bool __done__ = false;
    static lang__UInt64Class class = 
    {
        {
            {
                {
                    {
                        {
                            .instanceSize = sizeof(lang__UInt64),
                            .size = sizeof(void*),
                            .name = "UInt64",
                        },
                        .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                        .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                    },
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) ULLong_class();
        __done__ = true;
    }
    return &class;
}

lang__OctetClass *Octet_class(){
    static lang__Bool __done__ = false;
    static lang__OctetClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Octet),
                    .size = sizeof(void*),
                    .name = "Octet",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__SizeTClass *SizeT_class(){
    static lang__Bool __done__ = false;
    static lang__SizeTClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__SizeT),
                        .size = sizeof(void*),
                        .name = "SizeT",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LLong_class();
        __done__ = true;
    }
    return &class;
}

lang__String Bool_toString(lang__Bool this) {
    return this ? "true" : "false";
}

lang__BoolClass *Bool_class(){
    static lang__Bool __done__ = false;
    static lang__BoolClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Bool),
                    .size = sizeof(void*),
                    .name = "Bool",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__LDoubleClass *LDouble_class(){
    static lang__Bool __done__ = false;
    static lang__LDoubleClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__LDouble),
                    .size = sizeof(void*),
                    .name = "LDouble",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__DoubleClass *Double_class(){
    static lang__Bool __done__ = false;
    static lang__DoubleClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Double),
                        .size = sizeof(void*),
                        .name = "Double",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LDouble_class();
        __done__ = true;
    }
    return &class;
}

lang__FloatClass *Float_class(){
    static lang__Bool __done__ = false;
    static lang__FloatClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(lang__Float),
                        .size = sizeof(void*),
                        .name = "Float",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) LDouble_class();
        __done__ = true;
    }
    return &class;
}

lang__RangeClass *Range_class(){
    static lang__Bool __done__ = false;
    static lang__RangeClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Range),
                    .size = sizeof(void*),
                    .name = "Range",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}
lang__Range Range_new(lang__Int min, lang__Int max) {
    lang__Range this;
    this.min = min;
    this.max = max;
    return this;
}

void Exception_init_originMsg_impl(lang__Exception* this, lang__Class* origin, lang__String msg) {
    this->msg = msg;
    this->origin = origin;
}

void Exception_init_noOrigin_impl(lang__Exception* this, lang__String msg) {
    this->msg = msg;
}

void Exception_crash_impl(lang__Exception* this) {
    lang__Int x = 0;
    x = 1 / x;
}

lang__String Exception_getMessage_impl(lang__Exception* this) {
    lang__Int max = 1024;
    lang__String buffer = ((lang__String) GC_MALLOC(max));
    if (this->origin) {
        snprintf(buffer, max, "[%s in %s]: %s\n", ((lang__Object*) this)->class->name, this->origin->name, this->msg);
    }
    else {
        snprintf(buffer, max, "[%s]: %s\n", ((lang__Object*) this)->class->name, this->msg);
    }
    return buffer;
}

void Exception_print_impl(lang__Exception* this) {
    printf("%s", Exception_getMessage(this));
}

void Exception_throw_impl(lang__Exception* this) {
    Exception_print(this);
    Exception_crash(this);
}

lang__ExceptionClass *Exception_class(){
    static lang__Bool __done__ = false;
    static lang__ExceptionClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__Exception),
                    .size = sizeof(void*),
                    .name = "Exception",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
        .new_originMsg = Exception_new_originMsg,
        .init_originMsg = Exception_init_originMsg_impl,
        .new_noOrigin = Exception_new_noOrigin,
        .init_noOrigin = Exception_init_noOrigin_impl,
        .crash = Exception_crash_impl,
        .getMessage = Exception_getMessage_impl,
        .print = Exception_print_impl,
        .throw = Exception_throw_impl,
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void Exception_init_originMsg(lang__Exception* this, lang__Class* origin, lang__String msg) {
    ((lang__ExceptionClass *)((lang__Object *)this)->class)->init_originMsg((lang__Exception*)this, origin, msg);
}

void Exception_init_noOrigin(lang__Exception* this, lang__String msg) {
    ((lang__ExceptionClass *)((lang__Object *)this)->class)->init_noOrigin((lang__Exception*)this, msg);
}

void Exception_crash(lang__Exception* this) {
    ((lang__ExceptionClass *)((lang__Object *)this)->class)->crash((lang__Exception*)this);
}

lang__String Exception_getMessage(lang__Exception* this) {
    return (lang__String)((lang__ExceptionClass *)((lang__Object *)this)->class)->getMessage((lang__Exception*)this);
}

void Exception_print(lang__Exception* this) {
    ((lang__ExceptionClass *)((lang__Object *)this)->class)->print((lang__Exception*)this);
}

void Exception_throw(lang__Exception* this) {
    ((lang__ExceptionClass *)((lang__Object *)this)->class)->throw((lang__Exception*)this);
}
lang__Exception* Exception_new_originMsg(lang__Class* origin, lang__String msg) {
    lang__Exception* this = ((lang__Exception*) Class_alloc((lang__Class*) Exception_class()));
    Exception_init_originMsg(this, origin, msg);
    return this;
}
lang__Exception* Exception_new_noOrigin(lang__String msg) {
    lang__Exception* this = ((lang__Exception*) Class_alloc((lang__Class*) Exception_class()));
    Exception_init_noOrigin(this, msg);
    return this;
}

lang__String __OP_ADD_String_String__String(lang__String left, lang__String right) {
    return String_append(left, right);
}
