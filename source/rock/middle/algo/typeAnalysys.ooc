import ../[Type, BaseType, TypeDecl]
import ../tinker/[Resolver, Trail]


distanceFromObject: func(type: BaseType, trail: Trail, res: Resolver) -> Int {
    ref := type ref as TypeDecl
    ref resolve(trail, res)

    distance := 0
    while(ref && ref instanceOf?(TypeDecl) && !ref as TypeDecl isObjectClass()) {
        ref = ref superType as BaseType ref
        ref resolve(trail, res)
        distance += 1
    }

    if(ref && !ref instanceOf?(TypeDecl)) return -1
    distance
}

_sugarLevelsEqual?: func(type1, type2: Type) -> Bool {
    while(type1 instanceOf?(SugarType)) {
        if(type1 class != type2 class) {
            return false
        }
        (type1, type2) = (type1 as SugarType inner, type2 as SugarType inner)
    }
    true
}

_createSugarWith: func(inner, levels: Type) -> Type {
    construct := inner
    while(levels instanceOf?(SugarType)) {
        match (levels class) {
            case PointerType => construct = PointerType new(construct, construct token)
            case ArrayType => construct = ArrayType new(construct, levels as ArrayType expr, construct token)
            case ReferenceType => construct = ReferenceType new(construct, construct token)
            case => // Comon, how did you even get here?!
        }
    }
    construct
}

getInnermostType: func(type: Type) -> Type {
    while(type instanceOf?(SugarType)) {
        type = type as SugarType inner
    }
    type
}

// Returns the clsoer common root of two types
// A common root is a type that represents both of the types it comes from
// For example, if Bar extends Foo and Baz extends Foo, Foo is the closer common root of Foo and Bar
findCommonRoot: func(type1, type2: Type, trail: Trail, res: Resolver) -> Type {
    basic := func(t1, t2: Type) -> Type {
        if(t1 equals?(type2)) return t1

        if(t1 getScore(t2) > 0 || t2 getScore(t1) > 0) {
            score1 := t1 getScore(t2)
            score2 := t2 getScore(t1)
            // note the reverse order: this happens because the more general type is t2 when t1 vs t2 > 0
            return score1 > score2 ? t2 : t1
        }

        if(t1 void? || t2 void?) {
            return voidType
        }
        null
    }

    candidate := basic(type1, type2)
    if(candidate) return candidate

    // Ok, time to do magic
    // First, we unwrap our types from tha sugar, after we make sure our types have the same amount of sugar
    if(!_sugarLevelsEqual?(type1, type2)) return null

    unwrapped1 := getInnermostType(type1)
    unwrapped2 := getInnermostType(type2)

    if(!unwrapped1 instanceOf?(BaseType) || !unwrapped2 instanceOf?(BaseType)) return null
    // Get the base type hidden under the sugar
    btype1 := unwrapped1 as BaseType
    btype2 := unwrapped2 as BaseType
    // Get the "distance" of our base types from Object
    distance1 := distanceFromObject(btype1, trail, res)
    distance2 := distanceFromObject(btype2, trail, res)

    if(distance1 == -1 || distance2 == -1) return null

    // Go closer and closer to Object with the type that has the biggest distance, checking to see if we can return a root every time
    type1Bigger := distance1 > distance2
    biggerDistance :=  type1Bigger ? distance1 : distance2
    newType := type1Bigger ? btype1 : btype2
    while(biggerDistance > 0) {
        newType = newType ref as TypeDecl superType
        candidate := basic(newType, type1Bigger ? btype2 : btype1)
        // If we do have a root, then re-sugarize it and return it!
        if(candidate) return _createSugarWith(candidate, type1)
        biggerDistance -= 1
    }

    null
}
