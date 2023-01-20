#Initializinf the constant variables.
$ghostDir = "D:\G\.dreams\.Still"
#Uncomment to manually enter the ghost directory.
#$ghostDir = Read-Host -Prompt "Enter the ghost directory: "
$website = "www.xiuren.org"
$category = "feilin"
$line = "$website/$category"
$site = "$website\$category"
#Uncomment to read download list from file "list.txt"
#$line = Get-Content .\list.txt
for($folderNum=1001;$folderNum -ile 1350; $folderNum++)
{
$state="OK"
$paddedFolderNum = $folderNum.ToString()
$paddedFolderNum = $paddedFolderNum.Substring(1)
#Write-Output "Folder Number is: $paddedFolderNum"
if($false -ieq (Test-Path -Path "$ghostDir\$site\$paddedFolderNum"))
{
New-Item -ItemType Directory "$ghostDir\$site\$paddedFolderNum"
}
for($fileNum=10001;$fileNum -ile 10100; $fileNum++)
{
$paddedFileNum = $fileNum.ToString()
$paddedFileNum = $paddedFileNum.Substring(1)
#Write-Output "File is : $paddedFileNum.jpg"
$url = "http://$line/$paddedFolderNum/$paddedFileNum.jpg"
Write-Output "Url is: $url"
$newFile = "$ghostDir\$site\$paddedFolderNum\$paddedFileNum.jpg"
Write-Output "Destination is: $newFile"
Write-Output "State is: $state"
if("OK" -ieq $state -or "CK" -ieq $state)
{
if($false -ieq (Test-Path -Path $newFile))
{
$wc = New-Object System.Net.WebClient;
$wc.DownloadFile($url,$newFile);
$status=$?
Write-Output "Status is: $status"
}
else
{
Write-Output "File already exist."
$state="OK"
}
if($status)
{
Write-Output "Download suceeded."
$state="OK"
}
elseif ($false -ieq $status -and "CK" -ieq $state)
{
$state="NO"
}
elseif ($false -ieq $status -and "OK" -ieq $state)
{
$state="CK"
}
}
}#for
}#for