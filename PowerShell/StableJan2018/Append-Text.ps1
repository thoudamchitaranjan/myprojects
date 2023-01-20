<#
.Synopsis
    Appends text to the head or tail of each line in a file.
.PARAMETER
    FilePath
        The full path of the text file which is to be edited. Each line must already be seperated by a newline.
    SubString
        Provide the string to add to each line of the file.
    AppendToTail
        Choose to append to tail of each line. Default is set to append to head.
#>
param(
    [CmdletBinding()]

    [Parameter(
    mandatory=$true,
    Position=0,
    HelpMessage="The full path of the file which is to be edited.")]
    [ValidateScript({Test-Path $_})]
    [string]$FilePath,

    [Parameter(
    mandatory=$false,
    Position=1,
    HelpMessage="Provide the string to add to the file.")]
    [ValidateNotNullOrEmpty()]
    [string]$SubString,

    [Parameter(
    mandatory=$false,
    HelpMessage="Choose to append to tail of each line.")]
    [switch]$AppendToTail=$false
    )

    process{
        $tempFilePath=$FilePath -replace ".txt","Temp.txt"
        if(Test-Path $tempFilePath){
            Remove-Item $tempFilePath
        }
        foreach($line in Get-Content $FilePath){
            if($AppendToTail -and (-not [string]::IsNullOrWhiteSpace($line))){
                $newLine=-join("$line","$SubString")
                $newLine >> $tempFilePath
            }##if
            elseif(-not [string]::IsNullOrWhiteSpace($line)){
                $newLine=-join("$SubString","$line")
                $newLine >> $tempFilePath
            }##else
            
        }##foreach
        Remove-Item $FilePath | Out-Null
        Move-Item $tempFilePath -Destination $FilePath | Out-Null
        Write-Information -MessageData "Text Appended." -Verbose -InformationAction Continue
    }