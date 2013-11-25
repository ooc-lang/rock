import io/FileReader
import structs/[HashBag, Bag]
import text/json

// example.json taken from http://json.org/example.html
data := "
{\"glossary\": { \"title\": \"example glossary\", \"GlossDiv\": { \"title\": \"S\", \"GlossList\": { \"GlossEntry\": { \"ID\": \"SGML\", \"SortAs\": \"SGML\", \"GlossTerm\": \"Standard Generalized Markup Language\", \"Acronym\": \"SGML\", \"Abbrev\": \"ISO 8879:1986\", \"GlossDef\": { \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\", \"GlossSeeAlso\": [\"GML\", \"XML\"] }, \"GlossSee\": \"markup\" }}}}, \"foo\": [\"bar\", {\"muh\": \"kuh\", \"blargh\": [[[\"nope\"]]]}]}
"

main: func {
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
