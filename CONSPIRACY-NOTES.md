
Let's refer to the 'master' branch as '0.x' or 'pre-conspiracy', and
the 'conspiracy' branch as '1.x'.

### Step 1: Getting a working 0.x rock from a the fresh master branch

```
cd $DEV
git clone git://github.com/nddrylliog/rock.git rock-0.x
cd rock-0.x
make rescue
```

### Step 2: Compiling the 1.x branch with the 0.x compiler

Until here, it's mostly business as usual: however, you should make sure
that your 0.x rock uses your 0.x sdk

```
cd $DEV
git clone git://github.com/nddrylliog/rock.git rock-1.x
cd rock-1.x
git checkout conspiracy
make snowflake/NagaQueen.o
cp snowflake/NagaQueen.o .
ROCK_SDK=$DEV/rock-0.x/sdk OOC="$DEV/rock-0.x/bin/rock" make self
``` 
Now running `bin/rock -V` should display `rock 1.0.0-head` etc.

### Step 3: Compiling rock 1.x with the 1.x compiled from 0.x

The 1.x branch currently only has the make driver, but you'll see, it's
a surprisingly nice approach. It needs the 1.x sdk to work, obviously.

First, make a backup of your 1.x executable compiled with 0.x:

```
cd $DEV/rock-1.x
make backup
```

And then use that executable to compile another rock 1.x!

```
cd $DEV/rock-1.x
OOC=bin/safe_rock make self
cd snowflake
vim Makefile # escape the BUILD_DATE and BUILD_TIME strings (append and prepend `\"`), also perhaps CC=clang
time make -j8
```

You know have an 1.x compiled with 1.x in `$DEV/rock-1.x/snowflake/rock` !
You can move it to bin/rock, and use it again to compile itself.


