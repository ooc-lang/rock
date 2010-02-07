/* 001-pure-ooc-slembcke header file, generated with rock, the ooc compiler written in ooc */

#ifndef __001_pure_ooc_slembcke__
#define __001_pure_ooc_slembcke__

#include "001-pure-ooc-slembcke-fwd.h"

struct _KillableInterface {
    struct _lang__Object __super__;
};


struct _KillableReference {
    lang__Pointer obj;
    KillableInterfaceClass* impl;
};

struct _KillableDog {
    struct _KillableInterface __super__;
};


struct _Dog {
    struct _lang__Object __super__;
};


struct _KillableInterfaceClass {
    struct _lang__ClassClass __super__;
    KillableInterface* (*new)();
    void (*init)(KillableInterface*);
    lang__String (*dyingNoise)(KillableInterface*);
};


struct _KillableReferenceClass {
    struct _lang__ClassClass __super__;
};


struct _KillableDogClass {
    struct _KillableInterfaceClass __super__;
};


struct _DogClass {
    struct _lang__ClassClass __super__;
    Dog* (*new)();
    void (*init)(Dog*);
    lang__String (*trap)(Dog*);
    lang__String (*dyingNoise)(Dog*);
};


void kill(KillableReference ref);
lang__Int main();

#endif // __001_pure_ooc_slembcke__
