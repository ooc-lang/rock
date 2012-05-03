#!/bin/sh

rm -rf snowflake
ROCK_SDK=$PWD/sdk make self
rm -f snowflake/Makefile
cp /tmp/Makefile.bak snowflake/Makefile
cd snowflake && ROCK_DIST=~/rock/ make -j8 && ./rock -V

