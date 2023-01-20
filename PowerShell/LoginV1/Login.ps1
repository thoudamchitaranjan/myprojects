$KeyFile = "C:\Users\picachu\AppData\Roaming\Security\password.key"
$PasswordFile = "C:\Users\picachu\AppData\Roaming\Security\Password.txt"
$UserFile = "C:\Users\picachu\AppData\Roaming\Security\User.txt"
Function CreateKeyFile{
    param([string]$KeyFile)
    Write-Information -MessageData "Creating  key file..." -Verbose -InformationAction Continue
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($KeyFile)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($KeyFile)) -ItemType "Directory" | Out-Null
    }
    $Key = New-Object Byte[] 16 # You can use 16 (128-bit), 24 (192-bit), or 32 (256-bit) for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    $Key | Out-File $KeyFile
    Return $KeyFile
    }

Function Create-User{
    param([string]$KeyFile)
    Write-Information -MessageData "----- Creating user account." -Verbose -InformationAction Continue
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($UserFile)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($UserFile)) -ItemType "Directory" | Out-Null
    }
    $myCredential=Get-Credential -Message "Enter the credentials."
    $myCredential.UserName | Out-File $UserFile
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($PasswordFile)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($PasswordFile)) -ItemType "Directory" | Out-Null
    }
    if(-not [string]::IsNullOrWhiteSpace($KeyFile)){
        $Key=Get-Content $KeyFile
        $myCredential.Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
        }
        else{
            $myCredential.Password | ConvertFrom-SecureString | Out-File $PasswordFile
            }
    }###Create-User

### Safely compares two SecureString objects without decrypting them.
### Outputs $true if they are equal, or $false otherwise.
### Script block author: Bill_Stewart from Stack Overflow.
function Compare-SecureString {
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

Function Authenticate{
    param([string]$KeyFile)
    Write-Information -MessageData "----- Authenticating user." -Verbose -InformationAction Continue
    $User=Get-Content $UserFile
    $tempCredential= Get-Credential -Message "Enter the password." -UserName $User
    if(-not [string]::IsNullOrWhiteSpace($KeyFile)){
        $Key=Get-Content $KeyFile
        $SecurePassword= Get-Content $PasswordFile | ConvertTo-SecureString -Key $Key
        $myCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $User,$SecurePassword
        }
        else{
            $SecurePassword= Get-Content $PasswordFile | ConvertTo-SecureString
            $myCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $User,$SecurePassword
            }
    <#
    ###This code block uses less secure means of authentication.
    if($tempCredential.GetNetworkCredential().Password -ceq $myCredential.GetNetworkCredential().Password){
        Write-Output "Success"
        }
    #>
    $theyMatch = Compare-SecureString $tempCredential.Password $myCredential.Password
    if ( $theyMatch ) {
      Write-Information -MessageData "Good for login." -Verbose -InformationAction Continue
      Return $true
        }
        else{
            Return $false
            }
    }###Authenticate
    
    ##################################
    if(-not (Test-Path $UserFile) -or -not (Test-Path $PasswordFile)){
         Create-User
         }
    if(Authenticate){
        Return $true
        }
        else{
            Return $false
            }