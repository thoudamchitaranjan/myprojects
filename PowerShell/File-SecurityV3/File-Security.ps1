<#
.Version
    Version 3.0 Feb-23-2018
.Synopsis
    This Program strives to encrypt or decrypt files based on the Byte[] key derived from the Login.ps1 cmdlet. The encryptes file has a file extension of ".picachu".
    The program automatically decrypts any file with an extension of ".picachu". It encrypts any other files of any other extension.
.Syntax
    .\File-Security.ps1 -Path <string>
#>
param(
[Parameter(mandatory=$true,
HelpMessage="The file to be encrypted or decrypted.")]
[ValidateNotNullOrEmpty()]
[ValidateScript({Test-Path $_})]
[string]$Path
)
Begin{
    Write-Information -MessageData "`n" -Verbose -InformationAction Continue
    ([System.DateTime]::Now)
    $loginKey=.\Login.ps1 -Path $SaltIVFile
    if($loginKey -ne $null -and $loginKey.Length -gt 0){
        Write-Information -MessageData "`nYou are now Authenticated..." -Verbose -InformationAction Continue
        }
        else{
            Write-Information -MessageData "Failed to login!!!" -Verbose -InformationAction Continue
            Return $null
        }
    Function Create-Key{
        param(
            [Parameter(mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [Byte[]]$Salt
        )
        Begin{
        Function Decode-SecureString([SecureString]$SecureString){
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
        ### Safely compares two SecureString objects without decrypting them.
        ### Outputs $true if they are equal, or $false otherwise.
        ### Script block author: Bill_Stewart from Stack Overflow.
        Function Compare-SecureString {
          param(
            [Security.SecureString] $secureString1,
            [Security.SecureString] $secureString2
          )
          try {
            $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString1)
            $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString2)
            $length1 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr1, -4)
            $length2 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr2, -4)
            if ( $length1 -ne $length2 ) {
              return $false
            }
            for ( $i = 0; $i -lt $length1; ++$i ) {
              $b1 = [Runtime.InteropServices.Marshal]::ReadByte($bstr1, $i)
              $b2 = [Runtime.InteropServices.Marshal]::ReadByte($bstr2, $i)
              if ( $b1 -ne $b2 ) {
                return $false
              }
            }
            return $true
          }
          finally {
            if ( $bstr1 -ne [IntPtr]::Zero ) {
              [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
            }
            if ( $bstr2 -ne [IntPtr]::Zero ) {
              [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
            }
          }
        }###Compare-SecureString
        }#Begin
        Process{
        [SecureString]$securePassword = Read-Host -Prompt 'Enter password for the file' -AsSecureString
        [SecureString]$reSecurePassword = Read-Host -Prompt 'Re-enter password' -AsSecureString
        if(Compare-SecureString -secureString1 $securePassword -secureString2 $reSecurePassword){
                $iteration=1024
                ###Write-Information -MessageData "Salt is $salt" -Verbose -InformationAction Continue
                $Key=(new-object System.Security.Cryptography.Rfc2898DeriveBytes((Decode-SecureString -SecureString $securePassword),$salt,$iteration)).GetBytes(32)
                ###Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
                Return $Key
                }
            else{
                Write-Information -MessageData "Passwords did not match. Try again!" -Verbose -InformationAction Continue
                Return $null
                }
        
        }
    }

    Function Create-SaltIV{
            $salt = [Byte[]]::new(32)
            ([Security.Cryptography.RNGCryptoServiceProvider]::Create()).GetBytes($salt)
            ###(new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($salt) )[0..31]
            Write-Information -MessageData "Salt is $salt" -Verbose -InformationAction Continue
            
            $IV= [Byte[]]::new(16)
            ([System.Security.Cryptography.RNGCryptoServiceProvider]::Create()).GetBytes($IV)
            ###$IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($myCredential.GetNetworkCredential().Password) )[0..31]
            Write-Information -MessageData "IV   is $IV" -Verbose -InformationAction Continue
            $hash=@{"Salt" = $salt; "IV" = $IV;"Status"="Unlocked"}
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
        ###Write-Information -MessageData "`nEncrypting..." -Verbose -InformationAction Continue
        ###Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
        ###Write-Information -MessageData "IV is equal to $IV" -Verbose -InformationAction Continue
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
        ###Write-Information -MessageData "`nDecrypting..." -Verbose -InformationAction Continue
        ###Write-Information -MessageData "RFC key is $Key" -Verbose -InformationAction Continue
        ###Write-Information -MessageData "IV is equal to $IV" -Verbose -InformationAction Continue
        $aesManaged = Create-AesManagedObject $Key $IV
        $decryptor = $aesManaged.CreateDecryptor();
        $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
        $aesManaged.Dispose()
        [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
    }

    Function Lock-SaltIV($Path,$Key){
        $tempHash=Get-Content $Path -Raw | ConvertFrom-Json
        $secureSalt= ConvertTo-SecureString -String $tempHash.Salt -AsPlainText -Force
        $secureIV= ConvertTo-SecureString -String $tempHash.IV -AsPlainText -Force
        $secureSaltIV=@{"SecureSalt"=$secureSalt | ConvertFrom-SecureString  -Key $Key ; "SecureIV"=$secureIV | ConvertFrom-SecureString -Key $Key;"Status"="Locked"}
        Remove-Item $Path | Out-Null
        $secureSaltIV | ConvertTo-Json | Set-Content $Path
    }
    Function Get-SaltIV($Path,$Key){
        $tempHash=Get-Content $Path -Raw | ConvertFrom-Json
        $saltIV=@{"Salt"=$tempHash.SecureSalt | ConvertTo-SecureString -SecureKey $Key; "IV"=$tempHash.SecureIV | ConvertTo-SecureString -SecureKey $Key;"Status"="Unlocked"}
        Return $saltIV
    }
}###Begin
Process{
    $key=$null
    $IV=[Byte[]]::new(16)
    if(-NOT ($loginKey -ne $null -and $loginKey.Length -gt 0)){
            Return $null
        }
    while($null -ieq $key){
                    $key=Create-Key -Salt $loginKey
                }
    for($index=0;$index -lt 16;$index++){
        $IV[$index]=$loginKey[$index]
    }
    switch(".picachu" -ieq [System.IO.Path]::GetExtension($Path))
    {
        ($false){
                $destination=$Path+".picachu"
                if(Test-Path $destination){Remove-Item $destination}
                Write-Information -MessageData "`nEncrypting..." -Verbose -InformationAction Continue
                foreach($line in Get-Content $Path){
                    Encrypt-String $key $line | Out-File $destination -Append
                }
                if(Test-Path $destination){
                    Write-Information -MessageData "`nEncrypting done..." -Verbose -InformationAction Continue
                    }
            }
        ($true){
                $destination=[System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($Path),"Extract",[System.IO.Path]::GetFileNameWithoutExtension($Path))
                if(-not(Test-Path ([System.IO.Path]::GetDirectoryName($destination)))){
                    New-Item -Path ([System.IO.Path]::GetDirectoryName($destination)) -ItemType "Directory" | Out-Null
                }
                if(Test-Path $destination){Remove-Item $destination}
                Write-Information -MessageData "`nDecrypting..." -Verbose -InformationAction Continue
                foreach($line in Get-Content $Path){
                    Decrypt-String $key $line | Out-File $destination -Append
                }
                if(Test-Path $destination){
                    Write-Information -MessageData "`nDecrypting done..." -Verbose -InformationAction Continue
                    }
            }
    }###switch
}###Process
End{
    Remove-Variable "loginKey"
    Remove-Variable "key"
    Remove-Variable "IV"
}