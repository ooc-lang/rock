import structs/HashBag
import text/json/Generator

obj := HashBag new()
obj put("version", null as String)

s := generateString(obj)
s println()
if(s != "{\"version\":null}") {
    "Fail" println()
    exit(1)
} else {
    "Pass" println()
    exit(0)
}
