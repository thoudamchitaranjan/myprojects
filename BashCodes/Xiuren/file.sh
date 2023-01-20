#!/bin/bash
#_fileHolder="list.txt"
#IFS="/" line="$(<$_fileHolder)"
#echo ${line[1]}
w1="http:"
w2="www.xiuren.org"
w3="mistar"
w4="new"
w5="005"
w6=""
w7=""
w8=""
w9=""
echo "Completed" > "$w3$w4$w5$w6$w7$w8$w9".txt
if [ -e "$w3$w4$w5$w6$w7$w8$w9".txt ]; then
echo "$w3$w4$w5$w6$w7$w8${w9}.txt file exist"
fi
