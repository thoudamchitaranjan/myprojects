#!/bin/bash
./tasklistV1.sh
#Create Variables for processing.
_fileHolder=""
_listFile="list.txt"
_trackerFile=""
_missingListFile=""
#_trackerFile="temp\${_word3}Last.txt"
#_missingFile="temp\${_word3}Missing.txt"

#Check the formats of the provided links for protocols.
checkFormats "$_listFile"
if [ 0 -ne "$?" ]; then exit 1
echo "OK to proceed with download for the provided remote folders."
#############################################Initiating process for download of the list of categories, one at a time, in the order as provided in the list.
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
_list=("$_word1" "$_word2" "$_word3" "$_word4" "$_word5" "$_word6" "$_word7" "$_word8" "$_word9")
###Concatenation of the words to form the folders which contain the files.
_protocol="$_word1"
_dir="$_word2" ###Parse the name of the website without the slash to enable local directory creation.
echo Provided protocol is "$_protocol"
echo Home directory is: $_dir ###The Host server/website eg. "www.example.com"

###Formation of containing folder.
_tempDir="$_dir"
addFolderNo
echo Directory is: $_tempDir



#Initalizing the working space for the current selected category.
initializeFileNames
###Checking the status of download of the current category from its tracking file.
if [ -e "$_trackerFile" ]; then
###Checking the status of download of the current folder from the tracking file.
_trackerStatus="$(<$_trackerFile)"
if [ "Completed" != "$_trackerStatus" ]; then
###Continue download.

fi
echo "Completed" > "$_trackerFile"
fi

clearTempValues
done < "$_listFile"
