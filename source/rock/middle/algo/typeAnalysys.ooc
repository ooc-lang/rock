import ../[Type, BaseType]

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

findCommonRoot: func(type1, type2: Type) -> Type {
    if(type1 equals?(type2)) return type1

    if(type1 getScore(type2) > 0) {
        score1 := type1 getScore(type2)
        score2 := type2 getScore(type1)
        return score1 > score2 ? type1 : type2
    }

    if(type1 void? || type2 void?) {
        return voidType
    }

    // Ok, time to do magic
    // First, we unwrap our types from tha sugar, after we make sure our types have the same amount of sugar
    if(!_sugarLevelsEqual?(type1, type2)) return null

    unwrapped1 := getInnermostType(type1)
    unwrapped2 := getInnermostType(type2)

    if(!unwrapped1 instanceOf?(BaseType) || !unwrapped2 instanceOf?(BaseType)) return null
    // Get the base type hidden under the sugar
    btype1 := unwrapped1 as BaseType
    btype2 := unwrapped2 as BaseType
    null
}