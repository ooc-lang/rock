import io/FileReader
import structs/[HashBag, Bag]
import text/json

main: func {
    // example.json taken from http://json.org/example.html
    data := FileReader new("example.json") readAll()
    object := JSON parse(data, HashBag)

    fails := false

    printPath := func (path, reference: String) {
        value := object getPath(path, String)

        if (value != reference) {
            "Fail! should be %s, was:" printfln(reference)
            "%s => %s" printfln(path, value)
            fails = true
        }
    }

    printPath("glossary/title", "example glossary")
    printPath("glossary/GlossDiv/title", "S")
    printPath("glossary/GlossDiv/GlossList/GlossEntry/ID", "SGML")
    printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/para", "A meta-markup language, used to create markup languages such as DocBook.")
    printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/GlossSeeAlso#0", "GML")
    printPath("glossary/GlossDiv/GlossList/GlossEntry/GlossDef/GlossSeeAlso#1", "XML")

    printPath("foo#1/muh", "kuh")
    printPath("foo#1/blargh#0#0#0", "nope")

    if (fails) {
        "Fail" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
