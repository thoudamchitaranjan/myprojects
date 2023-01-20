#!/bin/bash
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
_list=("$_word1" "$_word2" "$_word3" "$_word4" "$_word5" "$_word6" "$_word7" "$_word8" "$_word9")
###Concatenation of the words to form the folders which contain the files.
_dir="$_word1/"
for _count in $(seq 1 9); do
echo List $_count is ${_list[$_count]}
if [ "${_list[$_count]}" ]; then
_dir="$_dir/${_list[$_count]}"
echo Directory is: $_dir
fi
done # For loop.
echo Directory is: $_dir
###Formation of next stage dynamic directory.
_tempDir="$_dir"
for _folderNo in $(seq 1 400); do
_tempDir="$_dir"
if [ "$_folderNo" -lt 10 ]; then
_tempDir="$_tempDir/00$_folderNo"
fi

if [ "$_folderNo" -ge 10 ] && [ "$_folderNo" -lt 100 ]; then
_tempDir="$_tempDir/0$_folderNo"
fi

if [ "$_folderNo" -ge 100 ]; then
_tempDir="$_tempDir/$_folderNo"
fi
echo Directory is: $_tempDir
###CHECKING EXISTENCE OF THE FIRST FILE inside the dynamic directory.
_state="NULL"
echo "Checking existence of first file:" "$_tempDir/0001.jpg"
########################################################################Code Verified till here.
wget --spider --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_tempDir/0001.jpg"
if [ 0 -eq "$?" ]; then
_state="OK"
echo $_state to proceed.
###Counting of file numbers and formation of file links for download begins.
for _fileCount in $(seq 1 100); do
if [ "$_fileCount" -lt 10 ]; then
_tempLink="$_tempDir/000$_fileCount.jpg"
fi
if [ "$_fileCount" -ge 10 ] && [ "$_fileCount" -lt 100 ]; then
_tempLink="$_tempDir/00$_fileCount.jpg"
fi
###Downloading
if [ "$_state"="OK" ]; then
echo Downloading $_tempLink
wget --no-clobber --directory-prefix=$_tempDir --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" $_tempLink
if [ 0 -ne "$?" ]; then
_state="BR"
echo Shifting to next volume.
fi
fi
done #Inner for loop.
fi

done #Outer for loop.

done <list.txt
