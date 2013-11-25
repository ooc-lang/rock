
/*  Test routines
    TODO use kinda builtin assert which doesnt crash when one test fails
    once unittest facility is builtin
*/

import text/StringTokenizer

allGood := true

extend String {
    failPrint: func {
        allGood = false
        println()
    }
}

Buffer_unittest: class {

    /*
    testFile: static func {
        // this one is a bit nasty :P
        // TODO make it work on windows as well
        TEST_FILE_IN : const String = "/usr/bin/env"
        TEST_FILE_OUT : const String = "/tmp/buftest"

        b := Buffer new(0)
        if (!b fromFile(TEST_FILE_IN) || b size == 0) "read failed: b size=%d" format(b size) failPrint()
        if (!(b toFile(TEST_FILE_OUT)))     ("write failed") failPrint()
        if (! ((c := Buffer new(0) fromFile(TEST_FILE_IN) )     == b ) ) ("comparison failed") failPrint()
    }
    */

    testFind: static func {
        b := "123451234512345"
        what := "1"
        p := b find(what, 0)
        p = b find(what, p+1)
        p = b find(what, p+1)

        l := b findAll( "1")
        if ( l size != ( 3 as SizeT)) ( "find failed 1") failPrint()
        else {
            if ( l get(0) != 0) ( "find failed 2") failPrint()
            if ( l get(1) != 5) ( "find failed 3") failPrint()
            if ( l get(2) != 10) ( "find failed 4") failPrint()
        }
    }

    testOperators: static func {
        if ("1" == "" ) ("op equals failed 3") failPrint()
        if ("123" == "1234" ) ("op equals failed 4") failPrint()
        if ("1234" != "1234" ) ("op equals failed 5") failPrint()
        if ("1234" == "4444" ) ("op equals failed 6") failPrint()
    }

    testReplace: static func {
        if ( "1234512345" replaceAll( "1", "2") != "2234522345")  ("replace failed 1," + "1234512345" replaceAll( "1", "2")) failPrint()
        if ( "1234512345" replaceAll( "12333333333333333333", "2") != "1234512345" )  ("replace failed 2") failPrint()
        if ( "1234512345" replaceAll( "23", "11") != "1114511145")  ("replace failed 3") failPrint()
        if ( "112" replaceAll( "1", "XXX") != "XXXXXX2" )  ("replace failed 4, " + "112" replaceAll( "1", "XXX")) failPrint()
        if ( "112" replaceAll( "1", "") != "2" )  ("replace failed 5") failPrint()
        if ( "111" replaceAll( "1", "") != "" )  ("replace failed 6") failPrint()
        if ( "" replaceAll( "1", "") != "" )  ("replace failed 7") failPrint()
        if ( "" replaceAll( "", "1") != "" )  ("replace failed 8") failPrint()
        if ( "111" replaceAll( "", "") != "111" )  ("replace failed 9") failPrint()
    }

    testSplit: static func {
        if (("X XXX X") split (" ") size != 3) ("split failed 1") failPrint()
        if (("X XXX X") split (" ") get(0) != "X")  ("split failed 2") failPrint()
        if (("X XXX X") split (" ") get(1) != "XXX")  ("split failed 3") failPrint()
        if (("X XXX X") split (" ") get(2) != "X")  ("split failed 4") failPrint()
    }

    testTrailingZero: static func {
        b := Buffer new(0)
        b setLength(4)
        b size = 0
        memcpy (b data as Char*, "1111", 4)
        b append("222")
        if (b data[3] != '\0') ("trZero failed 1") failPrint()
    }

    testSubstring: static func {
        if ("hors-saison" substring(0, 4) != "hors") ("hors-saison substring failed 1") failPrint()
        if ("hors-saison" substring(5) != "saison") ("hors-saison substring failed 2") failPrint()
        modulePath := "hors-saison.ooc"
        if (modulePath substring(0, modulePath length() - 4) != "hors-saison") ("hors-saison substring failed 3") failPrint()
        if (modulePath[0..(modulePath length() - 4)] != "hors-saison") ("hors-saison substring failed 4") failPrint()
        if ("my name's Joe"[3..7] != "name") ("hors-saison substring failed 5") failPrint()
    }

    testConcat: static func {
        result1 := ('/' + "usr" + '/' + "bin")
        if (result1 != "/usr/bin") ("testConcat failed 1, gave %s" format(result1)) failPrint()
    }

    unittest: static func {
        testOperators()
        //testFile()
        testFind()
        testReplace()
        testSplit()
        testTrailingZero()
        testSubstring()

        if (allGood) {
            "Pass" println()
        } else {
            "We've had failures." println()
            exit(1)
        }
    }

}

Buffer_unittest unittest()
