param(
[Parameter(mandatory=$true)]
[ValidateScript({Test-Path $_})]
[string]$Path,

[Parameter(mandatory=$false)]
[switch]$ReplaceOriginal=$false,

[Parameter(mandatory=$false)]
[ValidateScript({Test-Path $_})]
[string]$Destination,

[Parameter(mandatory=$false)]
[switch]$Decrypt=$false,

[Parameter(mandatory=$false)]
[string]$SaltIVFile="C:\Users\picachu\AppData\Roaming\Security\SaltIV.json"
)
Begin{
    if(.\Login.ps1){
        
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
            $hash=@{"Salt" = $salt.GetValue() ; "IV" = $IV.GetValue()}
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
    
    if(Test-Path $SaltIVFile){
                        $tempHash = Get-Content -Path $SaltIVFile -Raw| ConvertFrom-Json
                        $salt=New-Object Byte[] 32
                        $salt=[Byte[]]$tempHash.Salt.value
                        $IV=New-Object Byte[] 16
                        $IV=[Byte[]]$tempHash.IV.value
                        $SaltIV= @{"Salt" = $salt; "IV"= $IV}
                    }
                    else{
                        Write-Information -MessageData "SaltIVFile doesnot exist." -Verbose -InformationAction Continue
                        }
    switch($Decrypt)
    {
        ($true){
                if(-not (Test-Path $SaltIVFile)){
                        Return $null
                        }
                $Key=Create-Key -Salt $SaltIV.Salt
                $IV=$SaltIV.IV
                $tempFile=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $tempFile){Remove-Item $tempFile}
                foreach($line in Get-Content $Path){
                    Decrypt-String $Key $line | Out-File $tempFile -Append
                }
                Remove-Item -Path $Path
                Rename-Item -Path $tempFile -NewName ([System.IO.Path]::GetFileName($Path))
            }
        ($false){
                if(-not (Test-Path $SaltIVFile)){
                        $SaltIV=Create-SaltIV
                        $SaltIV | ConvertTo-Json | Set-Content  -Path $SaltIVFile
                        }
                $Key=Create-Key -Salt $SaltIV.Salt
                $IV=$SaltIV.IV
                $tempFile=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $tempFile){Remove-Item $tempFile}
                foreach($line in Get-Content $Path){
                    Encrypt-String $Key $line | Out-File $tempFile -Append
                }
                Remove-Item -Path $Path
                Rename-Item -Path $tempFile -NewName ([System.IO.Path]::GetFileName($Path))
            }
    }###switch

}###Process