/* place to place all kinds of hacks, that shall be globally available
    optimally, this file only has this comment inside */

// lame static function to be called by int main, so i dont have to metaprogram it
import structs/ArrayList

strArrayListFromCString: func (argc: Int, argv: Char**) -> ArrayList<String> {
    result := ArrayList<String> new ()
    for (i in 0..argc)  result add( argv[i] as CString toString() )
    result
}

/* damn, there's one probelm left. rock makes
source/rock/rock.ooc:4:12 ERROR No such function strArrayListFromCString(Int, String*)
 i make this quick hack here
 */
strArrayListFromCString: func~hack (argc: Int, argv: String*) -> ArrayList<String> {
    strArrayListFromCString(argc, argv as Char**)
}
