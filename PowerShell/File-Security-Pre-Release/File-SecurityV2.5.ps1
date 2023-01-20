param(
[Parameter(mandatory=$true,
HelpMessage="The file to be encrypted or decrypted.")]
[ValidateNotNullOrEmpty()]
[ValidateScript({Test-Path $_})]
[string]$Path,

[Parameter(mandatory=$false,
HelpMessage="Select this to replace the original file with the resulting file.")]
[ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
[switch]$ReplaceOriginal=$false,

[Parameter(mandatory=$false,
HelpMessage="The file where the result should be stored.")]
[ValidateNotNullOrEmpty()]
[ValidateScript({-not (Test-Path $_)})]
[ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
[string]$Destination,

[Parameter(mandatory=$false,
HelpMessage="Select this to decrypt the -Path file instead of encrypting it.")]
[switch]$Decrypt=$false,

[Parameter(mandatory=$false,
HelpMessage="The file (may or may not already exist) in json structure which contains the hashtable of Salt and IV values.")]
[ValidateNotNullOrEmpty()]
[string]$SaltIVFile="C:\Users\picachu\AppData\Roaming\Security\SaltIV.json"
)
Begin{
    $loginStatus=.\Login.ps1
    if($loginStatus){
        if(-not $ReplaceOriginal -and [string]::IsNullOrWhiteSpace($Destination)){
            Return $null
            } 
        }
        else{
            Return $null
        }
    Function Create-Key{
        param(
            [Parameter(mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [Byte[]]$Salt
        )
        [SecureString]$securePassword = Read-Host -Prompt 'Enter password' -AsSecureString
        $myCredential = New-Object System.Management.Automation.PSCredential -ArgumentList "$env:username",$securePassword
        [SecureString]$reSecurePassword = Read-Host -Prompt 'Re-enter password' -AsSecureString
        $reMyCredential = New-Object System.Management.Automation.PSCredential -ArgumentList "$env:username",$reSecurePassword
        if($reMyCredential.GetNetworkCredential().Password -cne $myCredential.GetNetworkCredential().Password){
            Write-Information -MessageData "Passwords did not match. Try again!" -Verbose -InformationAction Continue
            Return $null
        }
        $iteration=1024
            Write-Information -MessageData "Salt is $salt" -Verbose -InformationAction Continue
            $Key=(new-object System.Security.Cryptography.Rfc2898DeriveBytes($myCredential.GetNetworkCredential().Password,$salt,$iteration)).GetBytes(32)
            Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
            Return $Key
    }
    Function Create-SaltIV{
            $salt = New-Object Byte[] 32
            ([Security.Cryptography.RNGCryptoServiceProvider]::Create()).GetBytes($salt)
            ###(new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($salt) )[0..31]
            Write-Information -MessageData "Salt is $salt" -Verbose -InformationAction Continue
            
            $IV= New-Object Byte[] 16
            ([System.Security.Cryptography.RNGCryptoServiceProvider]::Create()).GetBytes($IV)
            ###$IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($myCredential.GetNetworkCredential().Password) )[0..31]
            Write-Information -MessageData "IV is equal to $IV" -Verbose -InformationAction Continue
            $hash=@{"Salt" = $salt; "IV" = $IV}
            Return $hash
            
    }

    Function Create-AesManagedObject($Key, $IV) {
        $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
        $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
        $aesManaged.BlockSize = 128
        $aesManaged.KeySize = 256
        if ($IV) {
                $aesManaged.IV = $IV
        }
        if ($Key) {
                $aesManaged.Key = $Key
        }
        $aesManaged
    }

    Function Encrypt-String($Key, $unencryptedString) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
        Write-Information -MessageData "`nEncrypting..." -Verbose -InformationAction Continue
        Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
        Write-Information -MessageData "IV is equal to $IV" -Verbose -InformationAction Continue
        $aesManaged = Create-AesManagedObject $Key $IV
        $encryptor = $aesManaged.CreateEncryptor()
        $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
        [byte[]] $fullData = $aesManaged.IV + $encryptedData
        $aesManaged.Dispose()
        [System.Convert]::ToBase64String($fullData)
    }

    Function Decrypt-String($Key, $encryptedStringWithIV) {
        $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
        $IV = $bytes[0..15]
        Write-Information -MessageData "`nDecrypting..." -Verbose -InformationAction Continue
        Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
        Write-Information -MessageData "IV is equal to $IV" -Verbose -InformationAction Continue
        $aesManaged = Create-AesManagedObject $Key $IV
        $decryptor = $aesManaged.CreateDecryptor();
        $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
        $aesManaged.Dispose()
        [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
    }

    }###Begin
Process{
    if($loginStatus){
        Write-Information -MessageData "`nYou are now Logged In..." -Verbose -InformationAction Continue
        if(-not $ReplaceOriginal -and [string]::IsNullOrWhiteSpace($Destination)){
            Write-Information -MessageData "`nEither provide -Destination or use -ReplaceOriginal switch.`nExiting..." -Verbose -InformationAction Continue
            Return $null
        } 
        }
        else{
            Write-Information -MessageData "Failed to login!!!" -Verbose -InformationAction Continue
            Return $null
        }
    if(Test-Path $SaltIVFile){
        Write-Information -MessageData "`nSaltIVFile detected." -Verbose -InformationAction Continue
        }
        elseif(-not $Decrypt){
            $SaltIV=Create-SaltIV
            $SaltIV | ConvertTo-Json | Set-Content  -Path $SaltIVFile
            Write-Information -MessageData "`nATTENTION: SaltIVFile created." -Verbose -InformationAction Continue
            }
            else{
                Write-Information -MessageData "`nATTENTION: SaltIVFile doesnot exist." -Verbose -InformationAction Continue
                Return $null
            }
    $tempHash = Get-Content -Path $SaltIVFile -Raw | ConvertFrom-Json
    $SaltIV= @{"Salt" = $tempHash.Salt; "IV"= $tempHash.IV}
    while($null -ieq $Key){
                    $Key=Create-Key -Salt $SaltIV.Salt.value
                }
    $IV=$SaltIV.IV.value
    switch($Decrypt)
    {
        ($true){
                $tempFile=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $tempFile){Remove-Item $tempFile}
                foreach($line in Get-Content $Path){
                    Decrypt-String $Key $line | Out-File $tempFile -Append
                }
            }
        ($false){
                $tempFile=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $tempFile){Remove-Item $tempFile}
                foreach($line in Get-Content $Path){
                    Encrypt-String $Key $line | Out-File $tempFile -Append
                }
            }
    }###switch
    if($ReplaceOriginal){
                Remove-Item -Path $Path
                Rename-Item -Path $tempFile -NewName ([System.IO.Path]::GetFileName($Path))
                }
                else{
                    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($Destination)))){
                        New-Item -Path ([System.IO.Path]::GetDirectoryName($Destination)) -ItemType "Directory" | Out-Null
                        }
                    Move-Item -Path $tempFile -Destination $Destination
                }
}###Process
End{
    Remove-Variable -Name "loginStatus"
}