#!/bin/bash

ROOT_DIR="$(cd "$(dirname $0)" && pwd)"

frame_file=$1
doc_file=$2

functions=`cat $1 | grep ^function | cut -d ' ' -f 2 | cut -d '(' -f 1`
for fun in $functions
do
    grep "$fun(" $doc_file > /dev/null || echo $fun not found in $doc_file
done
