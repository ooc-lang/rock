import io/FileReader
import structs/[HashBag, Bag]
import text/json

// example.json taken from http://json.org/example.html
data := FileReader new("example.json") readAll()
object := JSON parse(data, HashBag)

printPath: func (path: String) {
    "%s => %s" printfln(path, object getPath(path, String))
}

printPath("glossary/title")
printPath("glossary/GlossDiv/title")
printPath("glossary/GlossDiv/GlossList/GlossEntry/ID")
printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/para")
printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/GlossSeeAlso#0")
printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/GlossSeeAlso#1")

printPath("foo#1/muh")
printPath("foo#1/blargh#0#0#0")
