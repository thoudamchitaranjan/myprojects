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