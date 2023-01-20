#!/bin/bash
_fileHolder=""
_listFile="list.txt"
_trackerFile="bololiLast.txt"
if [ -e "$_trackerFile" ]; then
_fileHolder="$_trackerFile"
else
_fileHolder="$_listFile"
fi
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
_list=("$_word1" "$_word2" "$_word3" "$_word4" "$_word5" "$_word6" "$_word7" "$_word8" "$_word9")
###Concatenation of the words to form the folders which contain the files.

_dir=""
_protocol=""
if [ http: != "$_word1" -o https: != "$_word1" ]; then
echo Unspecified protocol. Continuing with http protocol.
_dir="$_word1/"
else
_protocol="$_word1//"
fi
_dir="$_word2" ###Parse the name of the website without the front slash to enable local directory creation.
_position=1
for _count in $(seq 2 9); do
if [ "${_list[$_count]}" ]; then
_position = $((_position++))
fi
done # For loop.
for _count in $(seq 2 9); do
echo List $_count is ${_list[$_count]}
if [ "$_count" -lt "$_position" ]; then
_dir="$_dir/${_list[$_count]}"
echo Directory is: $_dir
fi
done # For loop.
echo Next stage Directory is: $_dir
###Formation of next stage dynamic directory.
_tempDir="$_dir"
for _folderNo in $(seq "${_list[$_position]}" 400); do
_tempDir="$_dir"
if [ "$_folderNo" -lt 10 ]; then
_tempDir="$_tempDir/00$_folderNo"
fi

if [ "$_folderNo" -ge 10 -a "$_folderNo" -lt 100 ]; then
_tempDir="$_tempDir/0$_folderNo"
fi

if [ "$_folderNo" -ge 100 ]; then
_tempDir="$_tempDir/$_folderNo"
fi
echo Directory is: $_tempDir
###CHECKING EXISTENCE OF THE FIRST FILE inside the dynamic directory.
_state="NULL"
echo "Checking existence of first file:" "http://$_tempDir/0001.jpg"
########################################################################Code Verified till here.
wget --spider --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "http://$_tempDir/0001.jpg"
_value="$?"
echo "Checking existence of first file:" "http://$_tempDir/0002.jpg"
wget --spider --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "http://$_tempDir/0002.jpg"
if [ 0 -eq "$?" -o 0 -eq "$_value" ]; then
_state="OK"
echo "http://$_tempDir/" > "$_trackerFile"
echo $_state to proceed.
###Counting of file numbers and formation of file links for download begins here.
for _fileCount in $(seq 1 100); do
if [ "$_fileCount" -lt 10 ]; then
_tempLink="http://$_tempDir/000$_fileCount.jpg"
fi
if [ "$_fileCount" -ge 10 ] && [ "$_fileCount" -lt 100 ]; then
_tempLink="http://$_tempDir/00$_fileCount.jpg"
fi
###Downloading
if [ "$_state" = "OK" -o "$_state" = "CK" ]; then
echo Downloading $_tempLink
wget --no-clobber --directory-prefix=$_tempDir --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" $_tempLink
_value="$?"
if [ 0 -ne "$_value" -a "$_state" = "CK" ]; then
_state="BR"
echo Shifting to next volume.
elif [ 0 -ne "$_value" ]; then
_state="CK"
fi
if [ 0 -eq "$_value" ]; then
_state="OK"
fi
fi
done #Inner for loop.
fi

done #Outer for loop.

done <"$_fileHolder"
