#!/bin/bash

ROOT_DIR="$(cd "$(dirname $0)" && pwd)"/..

problem_files=`grep -r -e '^-\ .*:$' $ROOT_DIR/docs/* | cut -d ':' -f 1 | uniq`
for file in $problem_files
do
    cat $file | sed -e "s/^\-\ \(.*\):$/\-\ \1:\ \ /g" > $file.new
    mv $file.new $file
    echo $file
done
