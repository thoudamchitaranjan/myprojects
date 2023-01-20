<#
Version
    This is Version 2.0
.Synopsis
    This Program uses the Username and the Password of the credential to create a Byte[] key for accessing various personal files.
    By passing this login stage is of no use to anyone as there is no way to obtain the key without this algorithm.
.Syntax
    .\Login.ps1
.Parameters
    There is no parameters associated. It although returns a Byte[] key by using the Username and the Password.
.Examples
#>

Begin{
$AccountPath = "C:\Users\picachu\AppData\Roaming\Security"
Write-Information -MessageData "`n" -Verbose -InformationAction Continue
Function Create-Key{
    param(
    [Parameter(mandatory=$false)]
    [ValidateScript({-not ($PSBoundParameters['Random'])})]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(mandatory=$false)]
    [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Credential'])})]
    [switch]$Random=$false
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
    Write-Information -MessageData "Creating  key ..." -Verbose -InformationAction Continue
    $Key = [Byte[]]::new(32)
    $iteration=1024
    $tempSecureString=$Credential.Password.Copy()
    while($tempSecureString.Length -lt 16){ #charis 16-bit long in .Net ie it is Unicode. Hence max is 16*16=256(32byte)
                $tempSecureString.AppendChar('@')
            }
    }
    Process{
    if($Random){
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
        }
        else{
            ###$Key=(New-Object System.Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($keyCredential.GetNetworkCredential().Password))[0..15]
            ###$Key=(New-Object System.Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes((Decode-SecureString -SecureString $tempSecureString)))[0..31]
            $Key=(New-Object System.Security.Cryptography.Rfc2898DeriveBytes(($Credential.UserName+(Decode-SecureString -SecureString $tempSecureString)),$Key,$iteration)).GetBytes(32)
            ###$Key=(new-object System.Security.Cryptography.Rfc2898DeriveBytes($myCredential.GetNetworkCredential().Password,$salt,$iteration)).GetBytes(32)
        }
    Write-Information -MessageData "Returning  key ..." -Verbose -InformationAction Continue
    Return $Key
    }
}


Function Create-User{
    param(
    [Parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({-not (Test-Path $_)})]
    [String]$Destination,

    [Parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Byte[]]$Key
    )
    Write-Information -MessageData "`n----- Creating user account." -Verbose -InformationAction Continue
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($Destination)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($Destination)) -ItemType "Directory" | Out-Null
    }
    if(-not [string]::IsNullOrWhiteSpace($Key)){
        @{"UserName" = $Credential.UserName;"Password" = $Credential.Password | ConvertFrom-SecureString -key $Key} | ConvertTo-Json | Out-File $Destination
        }
        else{
            @{"UserName" = $Credential.UserName;"Password" = $Credential.Password | ConvertFrom-SecureString} | ConvertTo-Json | Out-File $Destination
            }
    if(Test-Path $Destination){
        Write-Information -MessageData "SUCCESS: User Account created." -Verbose -InformationAction Continue
        }
        else{
            Write-Information -MessageData "ATTENTION: Failed to create user account." -Verbose -InformationAction Continue
        }
}###Create-User

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

Function Authenticate{
    param(
    [Parameter(mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$Path,
    
    [Parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Byte[]]$Key
    )
    Write-Information -MessageData "`n----- Authenticating user." -Verbose -InformationAction Continue
    $tempHash=Get-Content $Path -Raw | ConvertFrom-Json
    
    if($Key -ne $null -and $key.Length -gt 0){
        $realCredential=New-Object System.Management.Automation.PSCredential -ArgumentList $tempHash.UserName,($tempHash.Password | ConvertTo-SecureString -Key $Key)
        }
        else{
            $realCredential=New-Object System.Management.Automation.PSCredential -ArgumentList $tempHash.UserName,($tempHash.Password | ConvertTo-SecureString)
            }
    $theyMatch = Compare-SecureString $realCredential.Password $Credential.Password
    if (( $theyMatch ) -and ($tempHash.UserName -eq $Credential.UserName)){
      Write-Information -MessageData "Good for login." -Verbose -InformationAction Continue
      Return $true
        }
        else{
            Write-Information -MessageData "Prevent login." -Verbose -InformationAction Continue
            Return $false
            }
    }###Authenticate

    Function Lock-SaltIV{
    PARAM(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$Path,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]$Key
        )
        $tempHash=Get-Content $Path -Raw | ConvertFrom-Json
        $secureSalt= ConvertTo-SecureString -String $tempHash.Salt -AsPlainText -Force
        $secureIV= ConvertTo-SecureString -String $tempHash.IV -AsPlainText -Force
        $secureSaltIV=@{"SecureSalt"=$secureSalt | ConvertFrom-SecureString  -SecureKey $Key ; "SecureIV"=$secureIV | ConvertFrom-SecureString -SecureKey $Key}
        Remove-Item $Path | Out-Null
        $secureSaltIV | ConvertTo-Json | Set-Content $Path
    }
    Function Get-SaltIV{
        PARAM(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$Path,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]$Key
        )
        $tempHash=Get-Content $Path -Raw | ConvertFrom-Json
        $saltIV=@{"Salt"=$tempHash.SecureSalt | ConvertTo-SecureString -SecureKey $Key; "IV"=$tempHash.SecureIV | ConvertTo-SecureString -SecureKey $Key}
        Return $saltIV
    }

}
Process{    
    ##################################
        ###[SecureString]$keyPassword=Read-Host -Prompt "Enter key:" -AsSecureString
        $credential=Get-Credential -Message "Enter the credentials.(Max 16 characters.)"
        $accountFilePath=[System.IO.Path]::ChangeExtension([System.IO.Path]::Combine($AccountPath,$credential.UserName),"json")
        ###$accountFilePath
        if($credential.Password.Length -gt 16){
            Write-Warning -Message "Password cannot be longer than 16 characters.`n`nExiting..." -Verbose -InformationAction Continue
        }
        $key=Create-Key -Credential $credential
        ###$key
        if($key -ieq $null){
            Return $null
        }
        ###$accountFilePath=[System.IO.Path]::ChangeExtension($accountFilePath,"json")
    if(-not (Test-Path $accountFilePath)){
                $reCredential=Get-Credential -Message "Re-Enter the credentials."
                if(Compare-SecureString -secureString1 $credential.Password -secureString2 $reCredential.Password){
                    Create-User -Destination $accountFilePath -Credential $credential -Key $key
                    ###Lock-SaltIV -Path $Path -Key $key
                    $reCredential.Password.Dispose()
                    }
                    else{
                        $reCredential.Password.Dispose()
                        Return $null
                        }
         }
    if(Authenticate -Path $accountFilePath -Credential $credential -Key $key){
        ###$SaltIV=Get-SaltIV -Path $Path -Key $key
        ###Return $SaltIV
        Return $key
        }
        else{
            Return $null
            }
}
End{
    $credential.Password.Dispose()
    $key.Clear()
}