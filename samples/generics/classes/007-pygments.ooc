Container: class <T> {
  content: T
  init: func(=content) {}
  get: func -> T { return content }
  set: func(=content) {}
}
 
main: func {
 
  cont1 := Container<Int> new(42)
  value := cont1 get()
  printf("value is an %s, and its value is %d\n", value class name, value)
 
}
