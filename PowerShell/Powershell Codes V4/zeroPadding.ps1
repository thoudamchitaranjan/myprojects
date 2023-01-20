for($folderNum=1000;$folderNum -ile 1350; $folderNum++)
{
$paddedFolderNum = $folderNum.ToString()
$paddedFolderNum = $paddedFolderNum.Substring(1)
Write-Output "Folder Number is: $paddedFolderNum"
for($fileNum=10001;$fileNum -ile 10100; $fileNum++)
{
$paddedFileNum = $fileNum.ToString()
$paddedFileNum = $paddedFileNum.Substring(1)
Write-Output "File is : $paddedFileNum.jpg"
}
}