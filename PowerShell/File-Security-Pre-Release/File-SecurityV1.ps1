param(
[Parameter(mandatory=$true)]
[ValidateScript({Test-Path $_})]
[string]$Path,

[switch]$Decrypt=$false
)
Begin{
    Function Format-Password($key_passphrase) {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($key_passphrase)
        $length = [Runtime.InteropServices.Marshal]::ReadInt32($bstr, -4)
        for ( $i = $length; $i -lt 32; ++$i ) {
          $b = [Runtime.InteropServices.Marshal]::WriteByte($bstr, $i, "0")
        }
        ###Return $key_passphrase
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($key_passphrase)
        $length = [Runtime.InteropServices.Marshal]::ReadInt32($bstr, -4)
        for ( $i = 0; $i -lt $length; ++$i ) {
          $Key[$i] = [Runtime.InteropServices.Marshal]::ReadByte($bstr, $i)
          $Key[$i]
        }
        for ( $i = $length; $i -lt 32; ++$i ) {
          $Key[$i] = $i
          $Key[$i]
        }
    }

    function Create-AesManagedObject($key, $IV) {
        $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
        $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
        $aesManaged.BlockSize = 128
        $aesManaged.KeySize = 256
        if ($IV) {
            if ($IV.getType().Name -eq "String") {
                $aesManaged.IV = [System.Convert]::FromBase64String($IV)
            }
            else {
                $aesManaged.IV = $IV
            }
        }
        if ($key) {
            if ($key.getType().Name -eq "String") {
                $aesManaged.Key = [System.Convert]::FromBase64String($key)
            }
            else {
                $aesManaged.Key = $key
            }
        }
        $aesManaged
    }

    function Encrypt-String($key, $unencryptedString) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
        $aesManaged = Create-AesManagedObject $key $IV
        $encryptor = $aesManaged.CreateEncryptor()
        $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
        [byte[]] $fullData = $aesManaged.IV + $encryptedData
        $aesManaged.Dispose()
        [System.Convert]::ToBase64String($fullData)
    }

    function Decrypt-String($key, $encryptedStringWithIV) {
        $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
        $IV = $bytes[0..15]
        $aesManaged = Create-AesManagedObject $key $IV
        $decryptor = $aesManaged.CreateDecryptor();
        $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
        $aesManaged.Dispose()
        [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
    }

    # key passphrase is a 16 byte string that is used to create the AES key.
    $key_passphrase = Read-Host -Prompt 'Enter password(Exactly 16 characters)'### -AsSecureString
    # base64 encode the key.  The resulting key should be exactly 44 characters (43 characters with a single = of padding) (256 bits)
    $Bytes = [System.Text.Encoding]::Ascii.GetBytes($key_passphrase)
    $key =[Convert]::ToBase64String($Bytes)

    # init is used to create the IV
    $init = "picachu@010"
    # converts init to a byte array (e.g. T = 84, h = 104) and then sha1 hash it
    $IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
    write-output "IV is equal to $IV"
    write-output "AES key is $key"
    }###Begin
Process{
    switch($Decrypt)
    {
        ($true){
                $destination=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $destination){Remove-Item $destination}
                foreach($line in Get-Content $Path){
                    Decrypt-String $key $line | Out-File $destination -Append
                }
                Remove-Item -Path $Path
                Rename-Item -Path $destination -NewName ([System.IO.Path]::GetFileName($Path))
        }
        ($false){
                $destination=[System.IO.Path]::ChangeExtension($Path,".temp")
                if(Test-Path $destination){Remove-Item $destination}
                foreach($line in Get-Content $Path){
                    Encrypt-String $key $line | Out-File $destination -Append
                }
                Remove-Item -Path $Path
                Rename-Item -Path $destination -NewName ([System.IO.Path]::GetFileName($Path))
        }
    }
<#    foreach($line in Get-Content $Path){
        $unencryptedString = $line
        $encryptedString = Encrypt-String $key $unencryptedString
        $backToPlainText = Decrypt-String $key $encryptedString

        write-output "`nUnencrypted string: $unencryptedString"
        write-output "Encrypted string: $encryptedString"
        write-output "Unencrytped string: $backToPlainText"
        Write-Output $backToPlainText >> ".\new.txt"
    }
#>
}###Process