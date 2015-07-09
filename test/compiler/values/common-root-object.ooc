
//! shouldfail

// This currently infers to Object[], crashes at C compile time
// After change: Incompatible types Float, String (covers vs. class)
a := [1, 2.0f, "String", 'v']

// a is now an Object (according to rock)
a := match 'a' {
    case 'a' => 0
    case => "Hello World!"
}

// Kaboom!
a class name println()
