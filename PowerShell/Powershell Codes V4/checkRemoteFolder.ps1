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
if("OK" -ieq $storedStatus.StatusCode){
return $true
}
$storedStatus.Close()
}
catch {
return $false
}
finally{
Remove-Variable -Name "info" -Scope Local
Remove-Variable -Name "storedStatus" -Scope Local
}
}
###############Function checkRemoteUrl ($url)



#$request = [System.Net.WebRequest]::Create('http://stackoverflow.com/questions/20259251/powershell-script-to-check-the-status-of-a-url')

#$response = $request.GetResponse()

#$response.StatusCode

#$response.Close()

checkRemoteUrl "http://www.xiuren.org/bololi/001/0001.jpg"