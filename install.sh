#!/bin/bash

[[ $# -ne 1 ]] && echo 'usage: ./install.sh <alias>' && exit

bundle install

sudo ln -is `pwd`/run.sh /usr/bin/$1
