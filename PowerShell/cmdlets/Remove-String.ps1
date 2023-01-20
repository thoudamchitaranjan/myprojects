#Remove-String.ps1

<#
.Synopsis
    Created especially to Convert the url-links of thumbnails to url-links of the actual files.
The values in -RemoveList are removed/replaced with value of -Substitute in the input-links.
Change the value of -RemoveList and -Substitute to adjust for each situation.
#>
param(
            [Parameter(mandatory=$true,
            Position=0,
            HelpMessage="The full path of the file which is to be edited.")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Test-Path $_})]
    [string]$Path,

            [Parameter(
            mandatory=$false,
            Position=1,
            HelpMessage="Destination list file full path.")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({-not (Test-Path $_)})]
            [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
    [string]$Destination,

            [Parameter(
            Position=2,
            HelpMessage="Enter one or more strings as keywords to be replaced in the lines content of the file.")]
            [ValidateNotNullOrEmpty()]
    [string[]]$RemoveList='Thum/Thum-',

            [Parameter(
            Position=3,
            HelpMessage="Enter one or more strings as keywords for substituting the keywords in the lines content of the file.")]
            [ValidateNotNullOrEmpty()]
    [string[]]$Substitute="",

            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to replace original file by the output file.")]
            [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
    [switch]$ReplaceOriginal=$false
    )
Process{
    $tempFilePath=$Path -replace ".txt","Temp.txt"
    if($false -ieq (Test-Path "$Path")){
        Return "List file does not exist."
        }
        else{
            foreach($keyword in $RemoveList){
                if(-not [string]::IsNullOrWhiteSpace($keyword)){
                    foreach($thumbnailLink in Get-Content "$Path"){
                        ###$thumbnailLink = $thumbnailLink.Replace($keyword,$Substitute)
                        $thumbnailLink = $thumbnailLink -replace $keyword,$Substitute
                        Write-Output $thumbnailLink >> $tempFilePath
                    }
                    Write-Information -MessageData  "Text $keyword removed from lines." -Verbose -InformationAction Continue
                }###if
           
            }###foreach()
        }###else
    if($ReplaceOriginal){
            Remove-Item $Path | Out-Null
            Rename-Item $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path)) | Out-Null
            }
            else{
                Move-Item -Path $tempFilePath -Destination $Destination | Out-Null
            }
 }
 end{
        Remove-Variable "tempFilePath"
    }