Function downloadFile($remoteSourceFileUrl,$localDestinationFileName){
New-Variable -Name "info" -Scope Local
New-Variable -Name "storedStatus" -Scope Local
try{
$wc = New-Object System.Net.WebClient;
$wc.DownloadFile($remoteSourceFileUrl,$localDestinationFileName);
$storedStatus=$?.ToString()
#Write-Output "Status is: $storedStatus"
if($true -ieq $storedStatus){
return $true
}
}
catch{
return $false
}
finally{
Remove-Variable -Name "info" -Scope Local
Remove-Variable -Name "storedStatus" -Scope Local
}
}

$status=downloadFile "http://www.xiuren.org/bololi/001/0001.jpg" "D:\0001.jpg"
Write-Output "Status is: $status"
$status=downloadFile "htpp://www.xiuren.org/bololi/350/0005.jpg" "D:\0005.jpg"
Write-Output "Status is: $status"