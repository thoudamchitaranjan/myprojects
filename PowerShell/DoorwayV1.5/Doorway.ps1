<#
.Version
    This is Version 1.5 which utilises the Byte[] key obtain by logging in through the Login.ps1 cmdlet.
    Without the Byte[] key, the ghost drive path cannot be read decrypted from the ghost file.
#>
param(
    [CmdletBinding()]
    [Parameter(mandatory=$false)]
    [string]$Action
)
Begin{
    Write-Information -MessageData "`n`n`n" -Verbose -InformationAction Continue
    Write-Information -MessageData "`n`n`n*******************Computer will be locked if you repeatedly enter wrong Password!*****************" -Verbose -InformationAction Continue
    Write-Information -MessageData "`n`n`n***********************Close if you don't know the Password!*****************" -Verbose -InformationAction Continue
    PAUSE
Function Decode-SecureString{
    Param(
    [Parameter(mandatory=$true,ValueFromPipeline=$true)]
    [SecureString]$SecureString
    )
                   Write-Information -MessageData "Retrieving string..." -Verbose -InformationAction Continue
                        try{
                        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                        $length = [Runtime.InteropServices.Marshal]::ReadInt32($bstr, -4)
                        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                        }
                        finally{
                            if ( $bstr -ne [IntPtr]::Zero ) {
                              [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                            }
                        }
        }
}
Process{
    $key=.\Login.ps1
    $Action=Read-Host -Prompt "Command>"
    if($key -ne $null -and $key.Length -gt 0){
        $source=$PSScriptRoot
        Write-Information -MessageData "Directory is: $source" -Verbose -InformationAction Continue
            IF(Test-Path "$source\ghost.txt"){
                $ghost=Get-Content -Path "$source\ghost.txt" | ConvertTo-SecureString -Key $key | Decode-SecureString
            }
            else{
                $ghost=Read-Host -Prompt "Enter ghost Directory"
                $ghost | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $key | Set-Content "$source\ghost.txt"
            }
        if($Action -imatch ".*source.*" ){
            $object=$source
        }
        else{
            $item=$Action -replace ".* (..*)",'$1'
            $object="$ghost\$item"
        }
        switch -Regex ("$Action")
        {
         ("Hide .*"){ start /min /realtime attrib +S +H "$object" /S /D }
         ("Show .*"){ start /min /realtime attrib -S -H "$object" /S /D }
         ("Open .*"){ Explorer.exe "$object" }
        }
    }
    else{Write-Warning -Message "Do not try again if you don't know the password." -Verbose -InformationAction Continue; pause}
}
End{
Remove-Variable key
Remove-Variable Action
}