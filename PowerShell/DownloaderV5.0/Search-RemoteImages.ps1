###All the output/resulting list files have a final extension of "List.txt" as in "filenameList.txt"

param(
[CmdletBinding()]

    [Parameter(mandatory=$true,
    Position=0,
    HelpMessage="The url of a webpost which has the images shown.")]
    [ValidateNotNullOrEmpty()]
[string]$Uri,

    [Parameter(mandatory=$true,
    Position=1,
    HelpMessage="The destination folder where images list are to be saved to.")]
    [ValidateNotNullOrEmpty()]
[string]$Destination,

[Parameter(mandatory=$false,
HelpMessage="Select this to delete previous list file. Otherwise, the new list will be added to the existing file list.")]
[switch]$DeletePrevious=$false
)###param

Begin{
Function Check-RemoteUrl{
<#
.Synopsis
        Checking remote link, like pinging, for availability of a link.
        This function does not give any output to any output device.
        It can only return true or false.
#>
        param (
            [Parameter(mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Url
            )
        begin{
            New-Variable -Name "info"
            New-Variable -Name "storedStatus"
            ###Write-Information -MessageData "`n" -Verbose -InformationAction Continue
        }
        process{
            $info = [System.Net.WebRequest]::Create("$Url")
            $info.UserAgent = ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
            $info.Timeout = 6000; # 6 secs max
            Write-Information -MessageData "Checking url -> $Url" -Verbose -InformationAction Continue
            $storedStatus = $info.GetResponse()
            ###Uncomment for debugging.
            ###$storedStatus
            try{
                $storedStatus.Close() | Out-Null
            }
            catch{
                return $false
            }
            if(("OK" -ieq $storedStatus.StatusCode) -or ("200" -ieq $storedStatus.StatusCode)){
                return $true
            }
            else{
                return $false
            }
        }
        end{
            Remove-Variable -Name "info"
            Remove-Variable -Name "storedStatus"
        }
}###Check-RemoteUrl() ends here.

Function Url-ToPath{
<#
.Syntax
    Url-ToPath.ps1 -Uri <string[]> -Destination <string> [-linux]
.Synopsis
    The return value is: supplied -Uri converted to local file system path and joined to -Destination folder path, which can be
    any Windows/Linux Directory path.
.Parameter
    -Uri :The url which is to be mapped to the local system.
    -Destination :The folder/directory path where the conveted url will be mapped.
    -linux :For Linux system.
#>
param(
    [CmdletBinding()]

    [Parameter(
    mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    HelpMessage="The url which will be converted to windows(by default) relative path.")]
    [ValidateNotNullOrEmpty()]
    [string[]]$Uri,

    [Parameter(mandatory=$true,
    Position=1,
    Helpmessage="Main folder path where the path converted from the url will be joined.")]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Parameter(
    mandatory=$false,
    Position=1,
    HelpMessage="Select this to convert to linux path instead of windows path.")]
    [switch]$linux=$false
    )
    begin{
        [string]$specialChars = "?*`"|<>:"
    }
    process{
        ###Removing special char for forming legal path.
        $actualLink=$Uri -replace ".*//(.*)",'$1'
        $rePattern = ($specialChars.ToCharArray() |ForEach-Object { [regex]::Escape($_) }) -join "|"
        $actualLink = $actualLink -replace $rePattern,""
        ###Applying checks...
        $actualLink=$actualLink.TrimEnd()
        $actualLink=$actualLink.TrimEnd("/")
        $path=$actualLink.TrimStart("/")
        $Destination=$Destination.TrimEnd()
        $Destination=$Destination.TrimStart()
        $Destination=$Destination.TrimEnd("/")
        $Destination=$Destination.TrimEnd("\")
        if($linux){
            $fullPath=([System.IO.Path]::Combine($Destination,$path))
            $fullPath=$fullPath -replace "\\","/"
            Return $fullPath
        }
        else{
            $fullPath=([System.IO.Path]::Combine($Destination,$path))
            $fullPath=$fullPath -replace "/","\"
            Return $fullPath
        }
    }
    end{
        Remove-Variable specialChars
    }
}###Url-ToPath() ends here.
    }
Process{
    Write-Information -MessageData "`n------------------------------->Deploying spider of $Uri" -Verbose -InformationAction Continue
    $imagesListFile=Url-ToPath -Uri "$Uri" -Destination $Destination
    $imagesListFile=([System.IO.Path]::ChangeExtension($imagesListFile,"txt"))
    $imagesListFile=$imagesListFile -replace ".txt","List.txt"
    if(($DeletePrevious) -and (Test-Path "$imagesListFile")){
        Remove-Item "$imagesListFile" | Out-Null
        }
        elseif(Test-Path "$imagesListFile"){
            Write-information -MessageData "ATTENTION: Images list file already exist." -Verbose -InformationAction Continue
            ###No operatiion performed.
            Return "$imagesListFile"
        }
    if(-not (Check-RemoteUrl $Uri)){
        ###Webpage exist.
        Write-Information -MessageData "ATTENTION: Webpage does not exist or No Connection.`n---Cancelled." -Verbose -InformationAction Continue
        Return $null
    }

        ###Write-Output "GOOD"
        ###$iwr=Invoke-WebRequest -Uri "$Uri" -UseBasicParsing
        ###$images=$iwr.Images | select src
        $images=Invoke-WebRequest -Uri $Uri | Select -ExpandProperty "Images" | select -ExpandProperty "src"
        $list=$images###.ToString()
        if(-not (Test-Path ([System.IO.Path]::GetDirectoryName("$imagesListFile")))){
            New-Item -Path ([System.IO.Path]::GetDirectoryName("$imagesListFile")) -ItemType Directory | Out-Null
        }
        $list=$list -replace "http://","`nhttp://"
        $list=$list -replace "https://","`nhttps://"
        $list=$list -replace "ftp","`nftp"
        $list=$list -replace ".jpg",".jpg`n"
        $list=$list -replace ".png",".png`n"
        $list=$list -replace " ","`n"
        Write-Output "$list" >> "$imagesListFile"
        Write-Information -MessageData "SUCCESS: Image-links list stored to: $imagesListFile" -Verbose -InformationAction Continue
        ###Success
        Return "$imagesListFile"

}
End{
    Remove-Variable "imagesListFile"
}