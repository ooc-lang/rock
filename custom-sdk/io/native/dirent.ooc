include dirent

DirPtr: cover from DIR*

DirEnt: cover from struct dirent {
    name: extern(d_name) String
    /* TODO: the struct has more members, actually */
}

closedir: extern func (DirPtr) -> Int
opendir: extern func (const String) -> DirPtr
readdir: extern func (DirPtr) -> DirEnt*
readdir_r: extern func (DirPtr, DirEnt*, DirEnt**) -> Int
rewinddir: extern func (DirPtr)
seekdir: extern func (DirPtr, Long)
telldir: extern func (DirPtr) -> Long 
