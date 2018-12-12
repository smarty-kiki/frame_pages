#!/bin/bash

FILE=$1

echo \# $FILE
echo 

cat $FILE | grep ^function | cut -d ' ' -f 2- | grep -v ^_ | while read line;do

echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo 

echo \#\#\# TODO
echo ----
echo \`\`\`php
echo TODO $line
echo \`\`\`
echo \#\#\#\#\# 参数

echo $line | cut -d '(' -f 2 | cut -d ')' -f 1 | tr \  "\n" | grep '^\$' | sed -e 's/,//g' | cut -d '$' -f 2 | while read p; do
echo "- $p:  "
echo "    TODO"
echo
done

echo \#\#\#\#\# 返回值
echo TODO
echo
echo \#\#\#\#\# 示例
echo \`\`\`php
echo TODO $line
echo \`\`\`
    
done
