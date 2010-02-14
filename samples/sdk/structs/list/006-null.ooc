import structs/[HashMap]

Cat: class {

  name: String

  init: func (=name) {}

}

main: func { 

  hm := HashMap<Cat> new()
  hm put("ohoh", Cat new("Catbert"))

  r1 := hm get("ohoh")
  printf("r1 = %p\n", r1)

  r2 := hm get("huhu")
  printf("r2 = %p\n", r2)

}
