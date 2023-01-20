#Downloading a file.
$state="OK"
$url="http://www.xiuren.org/mistar/001/0010.jpg";
$newFile="C:\Users\picachu\Pictures\Project\www.xiuren.org\mistar\001\0010.jpg";
#mkdir "C:\Users\picachu\Pictures\Project\www.xiuren.org\mistar\001\"
#New-Item -ItemType Directory "C:\Users\picachu\Pictures\Project\www.xiuren.org\mistar\001\"
if("OK" -ieq $state -or "CK" -ieq $state)
{
$wc = New-Object System.Net.WebClient;
$wc.DownloadFile($url,$newFile);
$status=$?
Write-Output "Status is: $status"
if($status)
{
Write-Output "Download suceeded."
}
elseif ("CK" -ieq $state)
{
$state="NO"
}
elseif ("OK" -ieq $state)
{
$state="CK"
}
}