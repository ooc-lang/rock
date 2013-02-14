import ../[Type, BaseType]


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
    null
}