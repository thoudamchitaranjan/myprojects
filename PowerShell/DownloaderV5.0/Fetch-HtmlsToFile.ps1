<#
.Synopsis
    This function fetches htmls from the webpage.
.Syntax
    Fetch-HtmlsToFile.ps1 -Uri <Url> -Destination <Folder Path> [-DeletePrevious]
.Parameters
    -Uri         : Url of webpage containing htmls for data mining.
    -Destination : The destination folder where href list are to be stored to.
    -DeletePrevious : Select this to delete previous list file. Otherwise, the new list will be added to the existing file list.
#>
param (
    [Parameter(mandatory=$true,
    Position=0,
    HelpMessage="Url of webpage containing htmls for data mining.")]
    [ValidateNotNullOrEmpty()]
    [string]$Uri,

    [Parameter(mandatory=$true,
    Position=1,
    HelpMessage="The destination folder where href list are to be stored to.")]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Parameter(mandatory=$false,
    HelpMessage="Select this to delete previous list file. Otherwise, the new list will be added to the existing file list.")]
    [switch]$DeletePrevious=$false
    )

Function Url-ToPath {
<#
        .Synopsis
            Returns the relative directory/file path for the supplied url, so that it can be used to join
            any Windows Directory path.
        .Parameter
            Select -linux to switch to linux type of path.
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
    }#######Url-ToPath() ends here.
       
       <#
        Function checkRemoteUrl {
        ###############Checking remote link, like pinging.
        ###This function cannot contain any output to any output device.
        ###It can only return true or false.
        param (
            [Parameter(mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Url
            )
        begin{
            New-Variable -Name "info"
            New-Variable -Name "storedStatus"
        }
        process{
            $info = [System.Net.WebRequest]::Create("$Url")
            $info.UserAgent = ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
            $info.Timeout = 6000; # 6 secs max
            $storedStatus = $info.GetResponse()
            try{
                $storedStatus.Close() | Out-Null
            }
            catch{
                return $false
            }
            if("OK" -ieq $storedStatus.StatusCode){
                return $true
            }
        }
        end{
            Remove-Variable -Name "info"
            Remove-Variable -Name "storedStatus"
        }
        }########checkRemoteUrl() ends here.
        #>
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
    
    Write-Information -MessageData "`n---------------------------->Attempting to fetch links..." -Verbose -InformationAction Continue
    $filePath=Url-ToPath -Uri $Uri -Destination $Destination
    $filePath=$filePath+".txt"
    if(($DeletePrevious) -and (Test-Path "$filePath")){
        Remove-Item "$filePath" | Out-Null
        }
        elseif(Test-Path "$filePath"){
            Write-information -MessageData "ATTENTION: HTMLS list file already exist." -Verbose -InformationAction Continue
            ###No operatiion performed.
            Return "$filePath"
        }
    if(-not (Check-RemoteUrl $Uri)){
        ###Webpage exist.
        Write-Information -MessageData "ATTENTION: Webpage does not exist or No Connection.`n---Cancelled." -Verbose -InformationAction Continue
        Return $null
    }
    
    $iwr = (Invoke-WebRequest -Uri "$Uri" -UseBasicParsing).Links.Href
    $list="$iwr"
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($filePath)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($filePath)) -ItemType Directory | Out-Null
    }
    if(Test-Path ([System.IO.Path]::GetDirectoryName($filePath))){
        $list=$list -replace "http://","`nhttp://"
        $list=$list -replace "https://","`nhttps://"
        $list=$list -replace "ftp","`nftp"
        $list=$list -replace " ","`n"
        Write-Output "$list" >> "$filePath"
        Write-Information -MessageData "SUCCESS: HTMLS fetched to: $filePath" -Verbose -InformationAction Continue
        ###Successful
        Return "$filePath"
        }
        else{
            Write-Information -MessageData "ATTENTION: Failed to create list file: `n--->$filePath" -Verbose -InformationAction Continue
            }
    ###Failed.
    Return $null