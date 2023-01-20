#Initializing the constant variables.
Set-Variable -Name "ghostDir" -Value "D:\G\.dreams\.Still"
#Uncomment to manually enter the ghost directory.
#$ghostDir = Read-Host -Prompt "Enter the ghost directory: "
Set-Variable -Name "website" -Value "www.xiuren.org"
#$category = Get-Content .\list.txt
foreach($category in Get-Content .\list.txt ) 
{
Write-Output "Category is $category"
Set-Variable -Name "siteLocal" -Value "$website\$category"
Set-Variable -Name "siteRemote" -Value "$website/$category"
for(Set-Variable -Name "folderNum" -Value 1001;$folderNum -ile 1350; $folderNum++)
{
Write-Output "`n"
Write-Output "Moving to next folder."
Set-Variable -Name "state" -Value "OK"
$paddedFolderNum = $folderNum.ToString()
$paddedFolderNum = $paddedFolderNum.Substring(1)
#Write-Output "Folder Number is: $paddedFolderNum"
Set-Variable -Name "url" -Value "http://$siteRemote/$paddedFolderNum/0001.jpg"
Write-Output "Url is: $url"
$info = [System.Net.WebRequest]::Create($url)
Set-Variable -Name "storedStatus" -Value $info.GetResponse()
$storedResponse = $storedStatus.StatusCode
$state = $storedResponse.ToString()
Write-Output "State is: $state"
Pause
if("OK" -ieq $state)
{
if($false -ieq (Test-Path -Path "$ghostDir\$siteLocal\$paddedFolderNum"))
{
New-Item -ItemType Directory "$ghostDir\$siteLocal\$paddedFolderNum"
}
}
else
{
$state = "CK"
}#if("OK" -ieq $state)

if("CK" -ieq $state)
{
Set-Variable -Name "url" -Value "http://$siteRemote/$paddedFolderNum/0002.jpg"
Write-Output "Url is: $url"
$info = [System.Net.WebRequest]::Create($url)
Set-Variable -Name "storedStatus" -Value $info.GetResponse()
$storedResponse = $storedStatus.StatusCode
$state = $storedResponse.ToString()
Write-Output "State is: $state"
if("OK" -ine $state)
{
$state = "NO"
}
if($false -ieq (Test-Path -Path "$ghostDir\$siteLocal\$paddedFolderNum"))
{
New-Item -ItemType Directory "$ghostDir\$siteLocal\$paddedFolderNum"
}
}
else
{
$state = "NO"
}#if

Write-Output "State is: $state"
if("NO" -ine $state)
{
for(Set-Variable -Name "fileNum" -Value 10001;$fileNum -ile 10100; $fileNum++)
{
if("NO" -ine $state)
{
Write-Output "`n"
Write-Output "Moving to next file."
$paddedFileNum = $fileNum.ToString()
$paddedFileNum = $paddedFileNum.Substring(1)
#Write-Output "File is : $paddedFileNum.jpg"
Set-Variable -Name url -Value "http://$siteRemote/$paddedFolderNum/$paddedFileNum.jpg"
Write-Output "Url is: $url"
Set-Variable -Name newFile -Value "$ghostDir\$siteLocal\$paddedFolderNum\$paddedFileNum.jpg"
Write-Output "Destination is: $newFile"


if("OK" -ieq $state -or "CK" -ieq $state)
{
$status=$null
$skipped="Skipped"
if($false -ieq (Test-Path -Path $newFile))
{
$wc = New-Object System.Net.WebClient;
$wc.DownloadFile($url,$newFile);
$status=$?.ToString()
Write-Output "Status is: $status"
}
else
{
$status="Skipped"
}#if($false -ieq (Test-Path -Path $newFile))

if($true.ToString() -ieq $status)
{
Write-Output "Download suceeded."
Set-Variable -Name "state" -Value "OK"
}
elseif ($skipped -ieq $status)
{
Write-Output "Download skipped. File already exist."
Set-Variable -Name "state" -Value "OK"
}
elseif ($false.ToString() -ieq $status -and "CK" -ieq $state)
{
$state="NO"
}
elseif ($false.ToString() -ieq $status -and "OK" -ieq $state)
{
Set-Variable -Name "state" -Value "CK"
}#if($true.ToString() -ieq $status)
Write-Output "State is: $state"
}#if("OK" -ieq $state -or "CK" -ieq $state)
}#if("NO" -ine $state)
}#for fileNum
}#if("NO" -ine $state)
}#for folderNum
}#foreach($category in Get-Content .\list.txt )