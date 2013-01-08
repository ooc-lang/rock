
// sdk stuff
import structs/ArrayList

// our stuff
import rock/frontend/drivers/SourceFolder
import rock/middle/UseDef

/**
 * Various flags that can be passed to the compiler/linker, classified
 * in two camps: compiler flags and linker flags
 *
 * :author: Amos Wenger (nddrylliog)
 */

Flags: class {

  compiler := ArrayList<String> new()
  linker := ArrayList<String> new()

  init: func {}

  fromSourceFolder: func (sourceFolder: SourceFolder) {
  }

  fromUseFile: func (useDef: UseDef) {
  }

}

