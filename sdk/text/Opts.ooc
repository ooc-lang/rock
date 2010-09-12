import structs/[ArrayList,HashMap]
import text/StringTokenizer

/**
    class for automated command line options parsing. pass it the ArrayList<String>
    received from main.

    Opts has "opts", a hashmap of key/value pairs, for flags and options
    and "args", for arguments that dont start with a "-"

    @author rofl0r
    use like this: http://gist.github.com/576154 or the example below.

    compilerPath := File new ( (opts set?("cc")) ? opts get("cc") : pathList find("gcc") )
    if (compilerPath exists?() && opts get?("driver") != "explain")
        raise ("couldnt find C compiler")
    opts args each(|cFile| compile(compilerPath, File new(cFile)) )

*/
Opts: class {

    opts: HashMap<String, String>
    args: ArrayList<String>

    init: func (cmdargs : ArrayList<String>) {
        opts = HashMap<String, String> new(cmdargs size)
        args = ArrayList<String> new(cmdargs size)
        if (cmdargs size > 0) {
            // add "self" option, which refers to the name of the executable
            opts add("self", cmdargs get(0))

            for (i in 1..cmdargs size) {
                arg := cmdargs get(i)
                if (arg startsWith?('-')) {
                    l := arg trimLeft('-') split('=',2)
                    arg2 := l size > 1 ? l get(1) : ""
                    opts add(l get(0), arg2)
                } else {
                    args add(arg)
                }
            }
        }
    }

    set?: func(s : String) -> Bool {
        (opts get(s) != null)
    }

    get: func(s: String) -> String {
        opts get(s)
    }

    toString: func -> String {
        res := Buffer new()
        opts each(|k, v|
            if (k != "self") {
                res append('-') .append(k) .append('=') .append(v) .append('\n')
            }
        )
        args each(|arg| res append(arg) .append('\n'))
        res toString()
    }
    /* we dont need an iterator for command line flags. but if one really wants
    to iterate, the can just iterate the opts map */
}