#This script algorithm is specifically created for accessing xiuren.org.
###Structure of functions in this script
###Function functionName {
###Write-Output "`n"
###[Function body lies here.]
###}
$Source = @"
using System.Net;
public class ExtendedWebClient : WebClient
{
public int Timeout;
protected override WebRequest GetWebRequest(System.Uri address)
{
WebRequest request = base.GetWebRequest(address);
if (request != null)
{
request.Timeout = Timeout;
}
return request;
}
public ExtendedWebClient()
{
Timeout = 600000; // Timeout value by default
}
}
"@;
Add-Type -TypeDefinition $Source -Language CSharp
#####################################Initializing Script variables
#Uncomment below to Scriptize variable.
New-Variable -Name "ghostDir" -Value "D:\G\.dreams\.still" -Scope Script #Nobody else knows what it is.
New-Variable -Name "listDir" -Value "C:\Users\picachu\AppData\Roaming\sourceFiles" -Scope Script #Nobody else knows what it is.
#New-Variable -Name "website" -Value "www.xiuren.org" -Scope Script #String.
#New-Variable -Name "website" -Scope Script #String.
#New-Variable -Name "currentCategory" -Scope Script #String Single line read from list.txt
#New-Variable -Name "paddedFolderNum" -Scope Script #String 1001..1350
#New-Variable -Name "paddedFileNum" -Scope Script #String 10001..10100
#New-Variable -Name "localSite" -Scope Script #String
#New-Variable -Name "remoteSite" -Scope Script #String Location in the remote system.
#New-Variable -Name "remoteStatus" -Scope Script #OK,CHECK(CK),SKIP(SK)
#New-Variable -Name "taskStatus" -Scope Script #SUCCESS,FAILED,SKIPPED
##############################Initalization finished.

##############################Function for clearing Variables
Function clearVariables {
Clear-Variable -Name "ghostDir" -Scope Script
Clear-Variable -Name "listDir" -Scope Script
#Clear-Variable -Name "website" -Scope Script
#Clear-Variable -Name "line" -Scope Script
#Clear-Variable -Name "folderNum" -Scope Script
#Clear-Variable -Name "fileNum" -Scope Script
#Clear-Variable -Name "localSite" -Scope Script
#Clear-Variable -Name "remoteSite" -Scope Script
#Clear-Variable -Name "remoteStatus" -Scope Script
#Clear-Variable -Name "taskStatus" -Scope Script
}
##################################Variables Cleared.

################################Function for clipping the first digit of the number.
Function clipNumber {
New-Variable "paddedNum" -Scope Local
$paddedNum = $args[0].ToString()
$paddedNum = $paddedNum.Substring(1)
return $paddedNum
}
################################Number clipped.

################################To assign category from list.txt
Function readLines ($fileName){
##############################Reading list
foreach($line in Get-Content "$Script:listDir\$fileName")
{
Write-Output "`n"
Write-Output "---------------COMING UP: [$line]-----------------"
Write-Output "`n"
#New-Variable -Name "dirFormat $line.Replace("/","\")
$Private:localSite = "$Script:ghostDir\"+$line.Replace("/","\")
$Private:remoteSite = "http://$line"
Write-Output "Site is: $Private:remoteSite/Add folder number here/Add file number here.jpg"
Write-Output "Directory is: $Private:localSite\Add folder number here\Add file number here.jpg"
###Assign folder number.
assignFolderNumbers $Private:remoteSite $Private:localSite

}#############################foreach List read done.
}################################Function readXiurenCategory

################################To assign folder numbers (001-350)
Function assignFolderNumbers ($Private:remoteCategoryLocation, $Private:localCategoryLocation) {
New-Variable -Name "localFolderLocation" -Scope Private
New-Variable -Name "remoteFolderLocation" -Scope Private
New-Variable -Name "folderStatus" -Scope Private
for(Set-Variable -Name "folderNum" -Value 1001;$folderNum -ile 1350; $folderNum++)
{
Write-Output "`n"
$Private:paddedFolderNum = clipNumber $folderNum
Write-Output "Folder Number is: $paddedFolderNum"
$Private:remoteFolderLocation = "$remoteCategoryLocation/$paddedFolderNum"
$private:localFolderLocation = "$localCategoryLocation\$paddedFolderNum"
Write-Output "Remote folder is: $Local:remoteFolderLocation"
Write-Output "Local Directory is: $Local:localFolderLocation"
###Check if the current folder number exist in the remote system.
###Check is done by pinging two random files of the folder and parsing their StatusCode.
if (checkRemoteUrl "$Local:remoteFolderLocation/0003.jpg"){
Write-Output "$Local:remoteFolderLocation exist."
$folderStatus = "OK"
}
elseif(checkRemoteUrl "$Local:remoteFolderLocation/0005.jpg"){
Write-Output "$Local:remoteFolderLocation exist."
$folderStatus = "OK"
}
else {
Write-Output "SKIPping remote folder:---$Local:remoteFolderLocation"
Write-Output "It doesnot exist."
$folderStatus = "SK"
}

###download here->
if("OK" -ieq $folderStatus){
###Creating current folder number in the "local system" if it exist in the remote system.
###Skip if already exist.
if($false -ieq (Test-Path -Path "$Local:localFolderLocation"))
{
New-Item -ItemType Directory "$Local:localFolderLocation"
}###if
#############################Assign file number.
assignFileNumbers $Local:remoteFolderLocation $Local:localFolderLocation
}###if folderStatus
else{
###deletes the folder if it is empty but exist anyway due to any error.
if($true -ieq (Test-Path -Path "$Local:localFolderLocation"))
{
deleteEmptyFolder $Local:localFolderLocation
}
else{
Write-Output "Prevented creation of local folder:---$Local:localFolderLocation"
}
}
Clear-Variable -Name paddedFolderNum -Scope Private
Write-Output "Moving to next folder."
}
Remove-Variable -Name localFolderLocation -Scope Private
Remove-Variable -Name remoteFolderLocation -Scope Private
Remove-Variable -Name folderStatus -Scope Private
}##############Function assignXiurenFolder ends here.

###############Checking remote link, like pinging.
###This function cannot contain any output to any output device.
###It can only return true or false.
Function checkRemoteUrl ($url) {
New-Variable -Name "info" -Scope Local
New-Variable -Name "storedStatus" -Scope Local
try{
$info = [System.Net.WebRequest]::Create($url)
$info.UserAgent = ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
$info.Timeout = 6000; # 6 secs
$storedStatus = $info.GetResponse()
$storedStatus.Close()
if("OK" -ieq $storedStatus.StatusCode){
return $true
}

}
catch {
return $false
}
finally{
Remove-Variable -Name "info" -Scope Local
Remove-Variable -Name "storedStatus" -Scope Local
}
}
###############checkRemoteUrl () ends here.

Function assignFileNumbers ($remoteFolder,$localFolder) {
New-Variable -Name "paddedFileNum" -Scope Private
New-Variable -Name "fileUrl" -Scope Private
New-Variable -Name "fileOut" -Scope Private
New-Variable -Name "folderStatus" -Value "OK" -Scope Private
New-Variable -Name "success" -Scope Private
for(Set-Variable -Name "fileNum" -Value 10001;$fileNum -ile 10100; $fileNum++)
{
Write-Output "`n"
$Private:paddedFileNum = clipNumber $fileNum
$Private:fileUrl = "$remoteFolder/$Private:paddedFileNum"+".jpg"
$Private:fileOut = "$localFolder\$Private:paddedFileNum"+".jpg"
###Check if the current file number exists in the local system.
if($false -ieq (Test-Path -Path $fileOut))
{
###Download current file number to the local system from the remote system.
###Skip if already exists.
###Skip the current folder number if download of consecutive file
###numbers greater than 50 failed.
if("OK" -ieq $folderStatus -or "CK" -ieq $folderStatus){
$success=downloadFile $Private:fileUrl $Private:fileOut
}
if($true -ieq $success){
$folderStatus = "OK"
Write-Output "$Private:fileUrl is downloaded successfully."
}

elseif($false -ieq $success -and "OK" -ieq $folderStatus){
$folderStatus = "CK"
}
elseif($false -ieq $success -and "CK" -ieq $folderStatus){
$folderStatus = "SK"
}
else{
$folderStatus="ERROR"
}
###Since we already know that the remote folder exist,
### so we check for files till 0050.jpg
if(10050 -ge $fileNum){
$folderStatus = "OK"
}
}
else
{
Write-Output "$Private:fileOut already exist."
}#if($false -ieq (Test-Path -Path $newFile))
Write-Output "Moving to next file."
}#for fileNum
Remove-Variable -Name "paddedFileNum" -Scope Private
Remove-Variable -Name "fileUrl" -Scope Private
Remove-Variable -Name "fileOut" -Scope Private
Remove-Variable -Name "folderStatus" -Scope Private
Remove-Variable -Name "success" -Scope Private
}###assignFileNumbers () ends here.

Function deleteEmptyFolder($Private:localFolderPath){
Write-Output "Checking folder: ---$Private:localFolderPath"
if(Test-Path -Path "$Local:localFolderPath\*.jpg"){
Write-Output "-------Folder is not empty."
Write-Output "----------------Listing files:-------------------"
Get-ChildItem -Path "$Local:localFolderPath"
}
else{
Write-Output "$Local:localFolderPath ->Folder is empty."
try{
###Write-Output "----------------Listing files:-------------------"
Get-ChildItem -Path "$Local:localFolderPath"
###Write-Output "----------------Deleting Folder:-------------------"
Remove-Item -Path "$Local:localFolderPath"
###Write-Output "$Local:localFolderPath ->Folder is deleted."
}
catch{
Write-Output "$Local:localFolderPath -> doesnot exist."
}
}###deleteEmptyFolder() ends here.

}
Function downloadFile($remoteSourceFileUrl,$localDestinationFileName){
New-Variable -Name "info" -Scope Local
New-Variable -Name "storedStatus" -Scope Local
try{
###$wc = New-Object System.Net.WebClient;
###$wc.DownloadFile($remoteSourceFileUrl,$localDestinationFileName);
$wc = New-Object ExtendedWebClient;
$wc.Timeout = 2000; # Change timeout for webClien
$wc.DownloadFile($remoteSourceFileUrl,$localDestinationFileName);
$storedStatus=$?.ToString()
if($true -ieq $storedStatus){
return $true
}
}
catch {
return $false
}
finally{
Remove-Variable -Name "info" -Scope Local
Remove-Variable -Name "storedStatus" -Scope Local
}
}
Clear-Host
Write-Output "--------About to start a critical process.-----------"
Write-Output "----------Close to exit or press Ctrl+C----------"
Pause
###[Main body lies here.]
Clear-Host
readLines "xiuren.txt"


###

Write-Output "---------------Download finished.------------------"
clearVariables