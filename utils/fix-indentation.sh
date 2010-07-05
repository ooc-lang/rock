#!/bin/bash

DIR=$(dirname $(readlink -f $0)) # Directory script is in
cd $DIR/..

find -name "*.ooc" -exec sed -ir 's/^ *$//g' {} \;
