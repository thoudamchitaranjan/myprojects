#!/bin/bash
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9;
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
_list=("$_word1" "$_word2" "$_word3" "$_word4" "$_word5" "$_word6" "$_word7" "$_word8" "$_word9")
echo List is: ${_list[0]} ${_list[1]} ${_list[2]} ${_list[3]} ${_list[4]} ${_list[5]} ${_list[6]} ${_list[7]} ${_list[8]} ${_list[9]}
echo Size of list is: ${#_list[@]}
###Concatenation of the words to form the folders which contain the files.
_dir="$_word1/"
_position=0
echo Directory is: $_dir
for _count in $(seq 1 9); do
echo List $_count is ${_list[$_count]}
if [ "${_list[$_count]}" ]; then
_dir="$_dir/${_list[$_count]}"
echo Directory is: $_dir
_position = $((_position++))
fi
done
echo Position is $_position
echo Folder Number is: ${_list[$_position]}
for _folderNo in $(seq "${_list[$_position]}" 400); do
echo Folder Number is: $_folderNo
done
_position=59
echo Position is $_position
for _folderNo in $(seq "$_position" 400); do
echo Folder Number is: $_folderNo
done
done < bololiLast.txt
