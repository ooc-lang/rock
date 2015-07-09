
//! shouldfail

SomeException: class extends Exception {
  init: func (.message) { super(message) }
}

main: func {
  // throws an Exception, should err
  SomeException new(String, "you dun goofed") throw()
}
