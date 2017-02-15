#!/bin/bash

[[ $# -ne 1 ]] && echo 'usage: ./install.sh <alias>' && exit

sudo ln -is `pwd`/helpers.rb /usr/bin/$1
