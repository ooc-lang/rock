#!/usr/bin/env sh

curl -k -L $1 || ftp -o - $1 || wget --no-check-certificate -O - $1 || wget -O - $1
