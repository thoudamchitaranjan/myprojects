$wc = New-Object System.Net.WebClient
try {

    $wc.OpenRead("http://www.xiuren.org/bololi/001/0001.jpg") | Out-Null
    Write-Output 'File Exists'

} catch {

    Write-Output 'Error / Not Found'

}

Function check {
$info = [System.Net.WebRequest]::Create("http://www.xiuren.org/bololi/001/0001.jpg")
$info.Timeout = 6000; # 6 secs
Set-Variable -Name "state" -Value $info.GetResponse()
$state = $state.StatusCode
if ($null -ine $storedResponse){
$state = $state.ToString()
}
Write-Output $state
return $false
}
$value = check
Write-Output "Return value is: $value"