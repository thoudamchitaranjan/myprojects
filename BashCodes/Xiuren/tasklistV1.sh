#!/bin/bash
#clearTempValues()
#reset()
#checkFormats()
#initializeFileNames()
#addFolderNo()
#addFileNo()
#checkAvailability()
#downloadFile()

clearTempValues()
{
_trackerFile=""
_missingListFile=""
}
reset()
{
}
checkFormats()
{
########################################################Checking the formats of the links.
echo "Checking the link formats in the file" "$1"
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
if [ "http:" = "$_word1" -o "https:" = "$_word1" ]; then
echo "\n"
echo Provided protocol is "$_word1"
else
echo "Error\! Unspecified protocol.\n     Provide protocol in the list and retry. Exiting\!"
exit 1
fi
if [ "" = "$_null" ]; then
echo "\n"
echo "This Link format is ok."
else
echo "Error\! Unrecognized link format after protocol. Exiting\!"
exit 1
fi
done < "$1"
###Link format checking finished.
exit 0
}
initializeFileNames()
{
_trackerFile="temp/${_word3}Last.txt"
_missingFile="temp/${_word3}Missing.txt"
}
getLastIndex()
{
_position=1 ###This will hold the last non-empty index of _list.
for _count in $(seq 2 9); do
if [ "${_list[$_count]}" ]; then
((_position += 1)) ###_position value is updated to the last non-empty index of _list.
fi
done # For loop.
echo Last non-empty index is $_position
exit $_position
}
printArray() ###First argument=Name of array
{
###Printing all the values of the _list.
for _count in $(seq 0 9); do
echo List $_count is ${1[$_count]} ###Printing the index number and the content in the _list.
done # For loop.
}

prepareRemoteDir() ###Takes the last non-empty index of array as first argument.
{
for _count in $(seq 2 9); do
if [ "$_count" -lt "$1" ]; then
_dir="$_dir/${_list[$_count]}" ###The last non-empty index of _list is neglected here.
echo _dir copied form _list is: $_dir
fi
done # For loop.
}

addFolderNo()
{
echo Directory without folder No. is: $_dir
_resumeNo=1 ###Folder Number for starting/resuming the download.
if [ -e "$_trackerFile" ]; then
_resumeNo="${_list[$1]}" ###Folder No. to be resumed from the _list of _trackerFile
else
_dir="$_dir/${_list[$_1]}" ###Deeper folder name is appended from the _list of _listFile
fi
for _folderNo in $(seq "$_resumeNo" 400); do
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
}
addFileNo()
{
}
checkAvailabilty()
{
}
downloadFile()
{
}

################################################################Reading from the chosen file.
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
_list=("$_word1" "$_word2" "$_word3" "$_word4" "$_word5" "$_word6" "$_word7" "$_word8" "$_word9")
###Concatenation of the words to form the folders which contain the files.
_protocol="$_word1"
_dir="$_word2" ###Parse the name of the website without the slash to enable local directory creation.
echo Home directory is: $_dir
echo Provided protocol is "$_protocol"

########################################Code Verified till here.
_position=1
for _count in $(seq 2 9); do
if [ "${_list[$_count]}" ]; then
((_position += 1))
fi
done # For loop.
echo Last non-empty index is $_position

echo List 0 is ${_list[0]}
echo List 1 is ${_list[1]}
for _count in $(seq 2 9); do
echo List $_count is ${_list[$_count]}
if [ "$_count" -lt "$_position" ]; then
_dir="$_dir/${_list[$_count]}"
echo _dir copied form _list is: $_dir
fi
done # For loop.
echo Next stage Directory is: $_dir
###Formation of containing folder.
_tempDir="$_dir"
_resumeNo=1
if [ -e "$_trackerFile" ]; then
_resumeNo="${_list[$_position]}"
else
_dir="$_dir/${_list[$_position]}"
fi
for _folderNo in $(seq "$_resumeNo" 400); do
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
###CHECKING REMOTE EXISTENCE OF THE FIRST FILE inside the next folder.
_state="NULL"
echo "Checking existence of first file:" "http://$_tempDir/0001.jpg"

###timeout 10 wget --spider --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_protocol//$_tempDir/0001.jpg"
_value="$?"
echo "Checking existence of first file:" "http://$_tempDir/0002.jpg"
###timeout 10  wget --spider --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_protocol//$_tempDir/0002.jpg"
if [ 0 -eq "$?" -o 0 -eq "$_value" ]; then
_state="OK"
echo "http://$_tempDir/" > "$_trackerFile"
echo $_state to proceed.
###Counting of file numbers and formation of file links for download begins here.
for _fileCount in $(seq 1 100); do
if [ "$_fileCount" -lt 10 ]; then
_tempLink="$_protocol//$_tempDir/000$_fileCount.jpg"
fi
if [ "$_fileCount" -ge 10 ] && [ "$_fileCount" -lt 100 ]; then
_tempLink="$_protocol//$_tempDir/00$_fileCount.jpg"
fi
###Downloading
if [ "$_state" = "OK" -o "$_state" = "CK" ]; then
echo Downloading $_tempLink
###timeout 60 wget --no-clobber --directory-prefix=".${_tempDir}" --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" $_tempLink
_value="$?"
if [ 0 -ne "$_value" -a "$_state" = "CK" ]; then
_state="BR"
echo Shifting to next volume.
elif [ 0 -ne "$_value" ]; then
_state="CK"
echo $_tempLink >> "$_missingFile"
fi
if [ 0 -eq "$_value" ]; then
_state="OK"
fi
fi
done #Inner for loop.
fi

done #Outer for loop.

done <"$_fileHolder"

