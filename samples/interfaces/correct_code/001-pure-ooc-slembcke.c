/* 001-pure-ooc-slembcke source file, generated with rock, the ooc compiler written in ooc */

#include "001-pure-ooc-slembcke.h"


void KillableInterface_init_impl(KillableInterface* this) {
}

KillableInterfaceClass *KillableInterface_class(){
    static lang__Bool __done__ = false;
    static KillableInterfaceClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(KillableInterface),
                    .size = sizeof(void*),
                    .name = "KillableInterface",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
        .new = KillableInterface_new,
        .init = KillableInterface_init_impl,
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void KillableInterface_init(KillableInterface* this) {
    ((KillableInterfaceClass *)((lang__Object *)this)->class)->init((KillableInterface*)this);
}

lang__String KillableInterface_dyingNoise(KillableReference ref) {
    return (lang__String) ((KillableInterfaceClass *) ref.impl)->dyingNoise((KillableInterface*) ref.obj);
}
KillableInterface* KillableInterface_new() {
    KillableInterface* this = ((KillableInterface*) Class_alloc((lang__Class*) KillableInterface_class()));
    KillableInterface_init(this);
    return this;
}

void KillableDog_init_impl(KillableDog* this) {
}

KillableDogClass *KillableDog_class(){
    static lang__Bool __done__ = false;
    static KillableDogClass class = 
    {
        {
            {
                {
                    {
                        .instanceSize = sizeof(KillableDog),
                        .size = sizeof(void*),
                        .name = "KillableDog",
                    },
                    .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                    .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
                },
            },
            .new = (KillableInterface* (*)()) KillableDog_new,
            .init = (void (*)(KillableInterface*)) KillableDog_init_impl,
            .dyingNoise = (void*) Dog_dyingNoise,
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) KillableInterface_class();
        __done__ = true;
    }
    return &class;
}

void KillableDog_init(KillableDog* this) {
    ((KillableInterfaceClass *)((lang__Object *)this)->class)->init((KillableInterface*)this);
}
KillableDog* KillableDog_new() {
    KillableDog* this = ((KillableDog*) Class_alloc((lang__Class*) KillableDog_class()));
    KillableDog_init(this);
    return this;
}

void Dog_init_impl(Dog* this) {
}

lang__String Dog_trap_impl(Dog* this) {
    return "HAHA it doesn't work";
}

lang__String Dog_dyingNoise_impl(Dog* this) {
    return "yowl";
}

DogClass *Dog_class(){
    static lang__Bool __done__ = false;
    static DogClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(Dog),
                    .size = sizeof(void*),
                    .name = "Dog",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
        .new = Dog_new,
        .init = Dog_init_impl,
        .trap = Dog_trap_impl,
        .dyingNoise = Dog_dyingNoise_impl,
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void Dog_init(Dog* this) {
    ((DogClass *)((lang__Object *)this)->class)->init((Dog*)this);
}

lang__String Dog_trap(Dog* this) {
    return (lang__String)((DogClass *)((lang__Object *)this)->class)->trap((Dog*)this);
}

lang__String Dog_dyingNoise(Dog* this) {
    return (lang__String)((DogClass *)((lang__Object *)this)->class)->dyingNoise((Dog*)this);
}
Dog* Dog_new() {
    Dog* this = ((Dog*) Class_alloc((lang__Class*) Dog_class()));
    Dog_init(this);
    return this;
}

void kill(KillableReference ref) {
    String_println(String_format("You killed it! It made a %s!", KillableInterface_dyingNoise(ref)));
}

lang__Int main() {
    GC_INIT();
    Dog* dog = Dog_new();
    KillableReference ref;
    ref.obj = dog;
    ref.impl = ((KillableInterfaceClass*) KillableDog_class());
    kill(ref);
    return 0;
}
