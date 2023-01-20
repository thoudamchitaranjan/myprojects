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
    HelpMessage="Select this to delete previous list file.")]
[switch]$DeletePrevious=$false
)###param

    $relativeFilePath=.\Url-ToPath.ps1 -Uri "$Uri"
    $relativeFilePath=([System.IO.Path]::ChangeExtension($relativeFilePath,"txt"))
    $imagesListFile=[System.IO.Path]::Combine($Destination,$relativeFilePath)
    if(($DeletePrevious) -and (Test-Path "$imagesListFile")){
        Remove-Item "$imagesListFile" | Out-Null
        }
        elseif(Test-Path "$imagesListFile"){
            ###Write-Verbose -Message "Images list file already exist." -Verbose
            Return "$imagesListFile"
        }
    $info=[System.Net.WebRequest]::Create("$Uri")
    $info.UserAgent=([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    $info.Timeout=6000;#6secs max
TRY{
    ###Write-Verbose -Message "Fetching image urls..." -Verbose
    $storedStatus=$info.GetResponse()
    $storedStatus.Close()
    if([string]::Equals("OK",$storedStatus.StatusCode)){
        ###Write-Output "GOOD"
        $iwr=Invoke-WebRequest -Uri "$Uri" -UseBasicParsing
        $images=$iwr.Images | select src
        $list=$images###.ToString()
        if(-not (Test-Path ([System.IO.Path]::GetDirectoryName("$imagesListFile")))){
            New-Item -Path ([System.IO.Path]::GetDirectoryName("$imagesListFile")) -ItemType Directory | Out-Null
        }
        Write-Output $list >> "$imagesListFile"
        Return "$imagesListFile"
    }
}
FINALLY{
    Remove-Variable "relativeFilePath"
    Remove-Variable "imagesListFile"
    }