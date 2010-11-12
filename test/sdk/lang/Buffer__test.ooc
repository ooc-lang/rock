
/*  Test routines
    TODO use kinda builtin assert which doesnt crash when one test fails
    once unittest facility is builtin
*/
Buffer_unittest: class {

    /*
    testFile: static func {
        // this one is a bit nasty :P
        // TODO make it work on windows as well
        TEST_FILE_IN : const String = "/usr/bin/env"
        TEST_FILE_OUT : const String = "/tmp/buftest"

        b := Buffer new(0)
        if (!b fromFile(TEST_FILE_IN) || b size == 0) "read failed: b size=%d" format(b size) println()
        if (!(b toFile(TEST_FILE_OUT)))     ("write failed") println()
        if (! ((c := Buffer new(0) fromFile(TEST_FILE_IN) )     == b ) ) ("comparison failed") println()
    }
    */

    testFind: static func {
        b := "123451234512345"
        what := "1"
        p := b find(what, 0)
        p = b find(what, p+1)
        p = b find(what, p+1)

        l := b findAll( "1")
        if ( l size != ( 3 as SizeT)) ( "find failed 1") println()
        else {
            if ( l get(0) != 0) ( "find failed 2") println()
            if ( l get(1) != 5) ( "find failed 3") println()
            if ( l get(2) != 10) ( "find failed 4") println()
        }
    }

    testOperators: static func {
        if ("1" == "" ) ("op equals failed 3") println()
        if ("123" == "1234" ) ("op equals failed 4") println()
        if ("1234" != "1234" ) ("op equals failed 5") println()
        if ("1234" == "4444" ) ("op equals failed 6") println()
    }

    testReplace: static func {
        if ( "1234512345" replaceAll( "1", "2") != "2234522345")  ("replace failed 1," + "1234512345" replaceAll( "1", "2")) println()
        if ( "1234512345" replaceAll( "12333333333333333333", "2") != "1234512345" )  ("replace failed 2") println()
        if ( "1234512345" replaceAll( "23", "11") != "1114511145")  ("replace failed 3") println()
        if ( "112" replaceAll( "1", "XXX") != "XXXXXX2" )  ("replace failed 4, " + "112" replaceAll( "1", "XXX")) println()
        if ( "112" replaceAll( "1", "") != "2" )  ("replace failed 5") println()
        if ( "111" replaceAll( "1", "") != "" )  ("replace failed 6") println()
        if ( "" replaceAll( "1", "") != "" )  ("replace failed 7") println()
        if ( "" replaceAll( "", "1") != "" )  ("replace failed 8") println()
        if ( "111" replaceAll( "", "") != "111" )  ("replace failed 9") println()
    }

    testSplit: static func {
        if (("X XXX X") split (" ") size != 3) Exception new ("split failed 1") throw()
        if (("X XXX X") split (" ") get(0) != "X")  ("split failed 2") println()
        if (("X XXX X") split (" ") get(1) != "XXX")  ("split failed 3") println()
        if (("X XXX X") split (" ") get(2) != "X")  ("split failed 4") println()
    }

    testTrailingZero: static func {
        b := Buffer new(0)
        b setLength(4)
        b size = 0
        memcpy (b data as Char*, "1111", 4)
        b append("222")
        if (b data[3] != '\0') ("trZero failed 1") println()
    }

    testSubstring: static func {
        if ("hors-saison" substring(0, 4) != "hors") ("hors-saison substring failed 1") println()
        if ("hors-saison" substring(5) != "saison") ("hors-saison substring failed 2") println()
        modulePath := "hors-saison.ooc"
        if (modulePath substring(0, modulePath length() - 4) != "hors-saison") ("hors-saison substring failed 3") println()
        if (modulePath[0..(modulePath length() - 4)] != "hors-saison") ("hors-saison substring failed 4") println()
        if ("my name's Joe"[3..7] != "name") ("hors-saison substring failed 5") println()
    }

    testConcat: static func {
        result1 := ('/' + "usr" + '/' + "bin")
        if (result1 != "/usr/bin") "testConcat failed 1, gave %s" printfln(result1)
    }

    unittest: static func {
        testOperators()
        //testFile()
        testFind()
        testReplace()
        testSplit()
        testTrailingZero()
        testSubstring()
    }

}

Buffer_unittest unittest()
